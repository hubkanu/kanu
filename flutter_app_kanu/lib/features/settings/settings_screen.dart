import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/member.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_text_field.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/auth_controller.dart';
import '../../state/theme_controller.dart';

/// Écran des paramètres : profil, apparence, notifications, légal.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _bio = TextEditingController();
  bool _initialized = false;
  bool _notifications = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final Member? self = ref.read(authControllerProvider).member;
      if (self != null) {
        _firstName.text = self.firstName;
        _lastName.text = self.lastName;
        _city.text = self.city;
        _bio.text = self.bio;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AuthController auth = ref.read(authControllerProvider.notifier);
    final bool ok = await auth.updateProfile({
      'prenom': _firstName.text.trim(),
      'nom': _lastName.text.trim(),
      'ville': _city.text.trim(),
      'bio': _bio.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profil mis à jour.' : 'Échec de la mise à jour.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode theme = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const SectionHeader(title: 'Apparence', overline: 'Préférences'),
          _themeSelector(context, theme),
          const Divider(height: 32),
          const SectionHeader(
            title: 'Notifications',
            overline: 'Alertes',
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
          ),
          SwitchListTile(
            value: _notifications,
            activeThumbColor: AppColors.red,
            title: const Text('Nouvelles compatibilités'),
            subtitle: const Text('Recevoir une alerte lors d’un nouvel accord'),
            onChanged: (bool v) => setState(() => _notifications = v),
          ),
          const Divider(height: 32),
          const SectionHeader(
            title: 'Mon profil',
            overline: 'Informations',
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: KanuTextField(
                    controller: _firstName,
                    label: 'Prénom',
                    validator: (String? v) =>
                        Validators.name(v, field: 'Le prénom'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: KanuTextField(
                    controller: _lastName,
                    label: 'Nom',
                    validator: (String? v) =>
                        Validators.name(v, field: 'Le nom'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: KanuTextField(
                    controller: _city,
                    label: 'Ville',
                    validator: (String? v) =>
                        Validators.required(v, field: 'La ville'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: KanuTextField(
                    controller: _bio,
                    label: 'Présentation',
                    maxLines: 4,
                    maxLength: 400,
                    hint: 'Parlez de vous en quelques lignes sincères…',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: KanuButton(
              label: 'Enregistrer',
              loading: ref.watch(authControllerProvider).busy,
              onPressed: _save,
            ),
          ),
          const Divider(height: 32),
          const SectionHeader(
            title: 'Confidentialité & légal',
            overline: 'Documents',
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
          ),
          _legalTile(context, 'Mentions légales', 'mentions-legales'),
          _legalTile(context, 'Conditions générales (CGU)', 'cgu'),
          _legalTile(context, 'Conditions de vente (CGV)', 'cgv'),
          _legalTile(
            context,
            'Politique de confidentialité',
            'confidentialite',
          ),
          _legalTile(context, 'Cookies', 'cookies'),
          _legalTile(context, 'Charte de sincérité', 'charte'),
          _legalTile(context, 'Protection des mineurs', 'protection-mineurs'),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            title: const Text('Supprimer mon compte'),
            onTap: () => _confirmDelete(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              '${AppConfig.appName} · version 1.0.0\n'
              'Édité par ${AppConfig.publisher}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeSelector(BuildContext context, ThemeMode theme) {
    final List<MapEntry<ThemeMode, String>> modes = [
      const MapEntry<ThemeMode, String>(ThemeMode.system, 'Système'),
      const MapEntry<ThemeMode, String>(ThemeMode.light, 'Clair'),
      const MapEntry<ThemeMode, String>(ThemeMode.dark, 'Sombre'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        children: modes.map((MapEntry<ThemeMode, String> e) {
          final bool selected = theme == e.key;
          return ChoiceChip(
            label: Text(e.value),
            selected: selected,
            onSelected: (_) =>
                ref.read(themeControllerProvider.notifier).setMode(e.key),
            selectedColor: AppColors.red.withValues(alpha: 0.2),
            side: BorderSide(
              color: selected ? AppColors.red : AppColors.border,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _legalTile(BuildContext context, String label, String slug) {
    return ListTile(
      leading: const Icon(Icons.description_outlined, color: AppColors.silver),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      onTap: () => context.push('/legal/$slug'),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est définitive : votre profil, vos messages et vos '
          'compatibilités seront supprimés. Contactez le support pour toute '
          'question.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Demander la suppression'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Votre demande a été transmise au support KANU.',
          ),
        ),
      );
    }
  }
}
