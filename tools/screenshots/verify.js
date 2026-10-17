// Diagnostic : active l'arbre de semantique Flutter (CanvasKit) et dumpe le
// texte visible de chaque ecran, pour verifier que les captures montrent les
// bons ecrans avec du contenu.

const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..', '..', 'flutter_app_kanu', 'build', 'web');
const PORT = 8732;
const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.wasm': 'application/wasm', '.png': 'image/png',
  '.otf': 'font/otf', '.ttf': 'font/ttf', '.woff': 'font/woff', '.woff2': 'font/woff2',
  '.symbols': 'application/octet-stream', '.bin': 'application/octet-stream',
};

const MEMBER = {
  id: 'demo_self', email: 'vous@exemple.fr', username: 'camille_demo',
  prenom: 'Camille', nom: 'Moreau', date_naissance: '1990-06-15T00:00:00.000',
  telephone: '+33 6 00 00 00 00', pays: 'France', ville: 'Lyon', genre: 'femme',
  situation_familiale: 'Celibataire', a_des_enfants: false, nombre_enfants: 0,
  desir_enfants: '', secteur_professionnel: 'Sante', statut_emploi: 'Salariee',
  religion: 'Croyante non pratiquante',
  bio: "Amoureuse des choses vraies et des projets qui durent. J'aime les longues conversations et les dimanches tranquilles.",
  photo: null, abonnement_statut: 'gratuit', abonnement_fin: null, questionnaire_complete: false,
};

const ROUTES = ['#/home', '#/search', '#/compatibility', '#/messages', '#/profile', '#/premium'];

function startServer(root) {
  const server = http.createServer((req, res) => {
    let urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    if (urlPath === '/') urlPath = '/index.html';
    const filePath = path.normalize(path.join(root, urlPath));
    fs.readFile(filePath, (err, data) => {
      if (err) { res.writeHead(404); res.end(); return; }
      res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath).toLowerCase()] || 'application/octet-stream' });
      res.end(data);
    });
  });
  return new Promise((r) => server.listen(PORT, '127.0.0.1', () => r(server)));
}

async function dumpText(page) {
  return page.evaluate(() => {
    const labels = [];
    document.querySelectorAll('flt-semantics, [aria-label], [role]').forEach((el) => {
      const t = (el.getAttribute && el.getAttribute('aria-label')) || el.textContent || '';
      const s = t.trim();
      if (s) labels.push(s);
    });
    return Array.from(new Set(labels));
  });
}

async function main() {
  const server = await startServer(ROOT);
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const context = await browser.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 3 });
  await context.addInitScript((m) => {
    localStorage.setItem('flutter.kanu.auth.token', JSON.stringify('demo-token'));
    localStorage.setItem('flutter.kanu.auth.member', JSON.stringify(JSON.stringify(m)));
    localStorage.setItem('flutter.kanu.onboarding.done', JSON.stringify(true));
    localStorage.setItem('flutter.kanu.consent.v1', JSON.stringify(true));
  }, MEMBER);
  await context.route(/1gjvo6i\.cserverhost\.cloud|kanu-rencontres\.com/, (r) => r.abort());

  const page = await context.newPage();
  await page.goto(`http://127.0.0.1:${PORT}/`, { waitUntil: 'load' });
  await page.waitForTimeout(4500);

  // Active la semantique pour exposer le texte au DOM.
  await page.evaluate(() => {
    const p = document.querySelector('flt-semantics-placeholder');
    if (p) p.click();
  });
  await page.waitForTimeout(500);

  for (const route of ROUTES) {
    await page.evaluate((h) => { window.location.hash = h; }, route);
    await page.waitForTimeout(2200);
    const labels = await dumpText(page);
    console.log(`\n=== ${route} ===`);
    console.log(labels.join(' | ').slice(0, 1200) || '(vide)');
  }

  await browser.close();
  server.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
