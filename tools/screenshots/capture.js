// Genere les captures App Store (iPhone + iPad) de KANU depuis le build web
// Flutter, en local sous Windows (aucun Mac requis).
//
// Prerequis : `flutter build web --release` deja execute dans flutter_app_kanu.
//
// Lecture : le build web utilise shared_preferences (localStorage). On pre-seed
// la session de demonstration pour atteindre les ecrans connectes, et on bloque
// le backend pour forcer le repli sur les donnees de demo (AppConfig.allowDemoFallback).

const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..', '..', 'flutter_app_kanu', 'build', 'web');
const OUT = path.resolve(__dirname, 'output');
const PORT = 8731;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.symbols': 'application/octet-stream',
  '.bin': 'application/octet-stream',
  '.ico': 'image/x-icon',
  '.map': 'application/json',
};

// Membre de demonstration identique a DemoData.currentMember (cf. Member.toJson).
const MEMBER = {
  id: 'demo_self',
  email: 'vous@exemple.fr',
  username: 'camille_demo',
  prenom: 'Camille',
  nom: 'Moreau',
  date_naissance: '1990-06-15T00:00:00.000',
  telephone: '+33 6 00 00 00 00',
  pays: 'France',
  ville: 'Lyon',
  genre: 'femme',
  situation_familiale: 'Celibataire',
  a_des_enfants: false,
  nombre_enfants: 0,
  desir_enfants: '',
  secteur_professionnel: 'Sante',
  statut_emploi: 'Salariee',
  religion: 'Croyante non pratiquante',
  bio: "Amoureuse des choses vraies et des projets qui durent. J'aime les longues conversations et les dimanches tranquilles.",
  photo: null,
  abonnement_statut: 'gratuit',
  abonnement_fin: null,
  questionnaire_complete: false,
};

// Tailles App Store : iPhone 6.9" (1320x2868) et iPad 13" (2064x2752).
const DEVICES = [
  { slug: 'iphone', viewport: { width: 440, height: 956 }, dsf: 3 },
  { slug: 'ipad', viewport: { width: 1032, height: 1376 }, dsf: 2 },
];

const SHOTS = [
  { name: '1_accueil', hash: '#/home', wait: 4500, first: true },
  { name: '2_recherche', hash: '#/search', wait: 2200 },
  { name: '3_accords', hash: '#/compatibility', wait: 2200 },
  { name: '4_messages', hash: '#/messages', wait: 2200 },
  { name: '5_profil', hash: '#/profile', wait: 2200 },
  { name: '6_premium', hash: '#/premium', wait: 2200 },
];

function startServer(root) {
  const server = http.createServer((req, res) => {
    let urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    if (urlPath === '/') urlPath = '/index.html';
    const filePath = path.normalize(path.join(root, urlPath));
    if (!filePath.startsWith(root)) {
      res.writeHead(403);
      res.end();
      return;
    }
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, {
        'Content-Type': MIME[ext] || 'application/octet-stream',
        'Cache-Control': 'no-store',
      });
      res.end(data);
    });
  });
  return new Promise((resolve) => server.listen(PORT, '127.0.0.1', () => resolve(server)));
}

async function main() {
  if (!fs.existsSync(ROOT)) {
    throw new Error(`Build web introuvable: ${ROOT}\nLancez d'abord: flutter build web --release`);
  }

  const server = await startServer(ROOT);
  const base = `http://127.0.0.1:${PORT}/`;
  console.log(`Serveur statique: ${base}`);

  const browser = await chromium.launch({
    headless: true,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });

  try {
    for (const device of DEVICES) {
      const outDir = path.join(OUT, device.slug);
      fs.mkdirSync(outDir, { recursive: true });

      const context = await browser.newContext({
        viewport: device.viewport,
        deviceScaleFactor: device.dsf,
        isMobile: false,
        hasTouch: false,
        locale: 'fr-FR',
      });

      await context.addInitScript((member) => {
        localStorage.setItem('flutter.kanu.auth.token', JSON.stringify('demo-token'));
        localStorage.setItem('flutter.kanu.auth.member', JSON.stringify(JSON.stringify(member)));
        localStorage.setItem('flutter.kanu.onboarding.done', JSON.stringify(true));
        localStorage.setItem('flutter.kanu.consent.v1', JSON.stringify(true));
      }, MEMBER);

      // Force le repli demo : aucune requete backend ne doit aboutir.
      await context.route(/1gjvo6i\.cserverhost\.cloud|kanu-rencontres\.com/, (route) => route.abort());
      await context.route(/\.(png|jpe?g|webp|gif)$/i, (route) => route.abort());

      const page = await context.newPage();
      page.on('pageerror', (err) => console.log(`  [pageerror] ${err.message}`));

      console.log(`\n== ${device.slug} (${device.viewport.width}x${device.viewport.height} @${device.dsf}x => ${device.viewport.width * device.dsf}x${device.viewport.height * device.dsf}) ==`);
      await page.goto(base, { waitUntil: 'load' });

      for (const shot of SHOTS) {
        if (!shot.first) {
          await page.evaluate((h) => {
            window.location.hash = h;
          }, shot.hash);
        }
        await page.waitForTimeout(shot.wait);
        const file = path.join(outDir, `${shot.name}.png`);
        await page.screenshot({ path: file });
        console.log(`  ${shot.name}.png`);
      }

      await context.close();
    }
  } finally {
    await browser.close();
    server.close();
  }

  console.log(`\nCaptures ecrites dans: ${OUT}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
