import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/member.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_text_field.dart';
import '../../shared/widgets/section_header.dart';
import '../../state/auth_controller.dart';

/// Formulaire d'inscription complet.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _children = TextEditingController(text: '0');

  DateTime? _birthDate;
  Gender? _gender;
  String _country = 'France';
  String _familyStatus = '';
  String _wantsChildren = 'pas_sur';
  String _professionalField = '';
  String _employmentStatus = '';
  String _religion = '';
  bool _hasChildren = false;
  bool _charte1 = false;
  bool _charte2 = false;

  static const List<String> _countries = [
    'France',
    'Belgique',
    'Suisse',
    'Canada',
    'Luxembourg',
    'Autre',
  ];
  static const List<String> _familyStatuses = [
    'Célibataire',
    'Divorcé(e)',
    'Séparé(e)',
    'Veuf(ve)',
  ];
  static const List<String> _religions = [
    'Pratiquant(e)',
    'Croyant(e) non pratiquant(e)',
    'Spirituel(le) sans religion',
    'Athée',
  ];
  static const List<MapEntry<String, String>> _wantsChildrenOpts = [
    MapEntry<String, String>('oui', 'Oui'),
    MapEntry<String, String>('non', 'Non'),
    MapEntry<String, String>('plus_tard', 'Peut-être plus tard'),
    MapEntry<String, String>('pas_sur', 'Je ne sais pas encore'),
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _city.dispose();
    _password.dispose();
    _confirm.dispose();
    _children.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 35),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Votre date de naissance',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (Validators.birthDate(_birthDate) != null) {
      _snack('Merci d’indiquer une date de naissance valide (18 ans min).');
      return;
    }
    if (_gender == null) {
      _snack('Merci de préciser votre genre.');
      return;
    }
    if (_familyStatus.isEmpty) {
      _snack('Merci de préciser votre situation familiale.');
      return;
    }
    if (!_charte1 || !_charte2) {
      _snack('Vous devez accepter les deux engagements de la charte.');
      return;
    }

    final RegistrationData data = RegistrationData(
      email: _email.text.trim(),
      password: _password.text,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      birthDate: _birthDate!,
      phone: _phone.text.trim(),
      country: _country,
      city: _city.text.trim(),
      gender: _gender!,
      familyStatus: _familyStatus,
      hasChildren: _hasChildren,
      childrenCount:
          _hasChildren ? (int.tryParse(_children.text) ?? 0) : 0,
      wantsChildren: _wantsChildren,
      professionalField: _professionalField,
      employmentStatus: _employmentStatus,
      religion: _religion,
    );

    final bool ok =
        await ref.read(authControllerProvider.notifier).register(data);
    if (!mounted) return;
    if (ok) {
      context.go('/questionnaire');
    } else {
      final String? err = ref.read(authControllerProvider).errorMessage;
      if (err != null) _snack(err);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = ref.watch(authControllerProvider).busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const SectionHeader(
                title: 'Votre identité',
                overline: 'Étape 1',
              ),
              _field(
                child: KanuTextField(
                  controller: _firstName,
                  label: 'Prénom',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.name(v, field: 'Le prénom'),
                ),
              ),
              _field(
                child: KanuTextField(
                  controller: _lastName,
                  label: 'Nom',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) => Validators.name(v, field: 'Le nom'),
                ),
              ),
              _field(
                child: KanuTextField(
                  controller: _email,
                  label: 'Adresse e-mail',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
              ),
              _field(
                child: KanuTextField(
                  controller: _phone,
                  label: 'Téléphone',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
              ),
              _field(child: _birthDateField()),
              _field(
                child: KanuTextField(
                  controller: _password,
                  label: 'Mot de passe',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
              ),
              _field(
                child: KanuTextField(
                  controller: _confirm,
                  label: 'Confirmer le mot de passe',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.confirmPassword(v, _password.text),
                ),
              ),
              const SectionHeader(
                title: 'Votre profil',
                overline: 'Étape 2',
              ),
              _field(child: _genderField()),
              _field(child: _countryField()),
              _field(
                child: KanuTextField(
                  controller: _city,
                  label: 'Ville',
                  prefixIcon: Icons.location_city_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      Validators.required(v, field: 'La ville'),
                ),
              ),
              _field(child: _familyStatusField()),
              _field(child: _roleField('Secteur professionnel',
                  _professionalField, _setProfessionalField)),
              _field(child: _roleField(
                  'Statut professionnel', _employmentStatus, _setEmployment)),
              _field(child: _religionField()),
              _field(child: _childrenSwitch()),
              if (_hasChildren)
                _field(
                  child: KanuTextField(
                    controller: _children,
                    label: 'Nombre d’enfants',
                    prefixIcon: Icons.child_care_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              _field(child: _wantsChildrenField()),
              const SectionHeader(
                title: 'Charte de sincérité',
                overline: 'Étape 3',
              ),
              _charteTile(
                value: _charte1,
                onChanged: (bool v) => setState(() => _charte1 = v),
                text: 'Je certifie que les informations fournies sont exactes '
                    'et que ma démarche est sincère.',
              ),
              _charteTile(
                value: _charte2,
                onChanged: (bool v) => setState(() => _charte2 = v),
                text: 'J’accepte les CGU et la politique de confidentialité '
                    'de KANU.',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: KanuButton(
                  label: 'Créer mon profil',
                  loading: busy,
                  onPressed: _submit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: KanuButton(
                  label: 'J’ai déjà un compte',
                  variant: KanuButtonVariant.ghost,
                  onPressed: () => context.go('/login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setProfessionalField(String v) => setState(() => _professionalField = v);
  void _setEmployment(String v) => setState(() => _employmentStatus = v);

  Widget _field({required Widget child}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: child,
      );

  Widget _birthDateField() {
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium;
    return InkWell(
      onTap: _pickBirthDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.cake_outlined, size: 20),
        ),
        child: Text(
          _birthDate == null
              ? 'Date de naissance'
              : Formatters.shortDate(_birthDate),
          style: _birthDate == null
              ? style?.copyWith(color: AppColors.muted)
              : style,
        ),
      ),
    );
  }

  Widget _genderField() => DropdownButtonFormField<Gender>(
        initialValue: _gender,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.wc_outlined, size: 20),
        ),
        hint: const Text('Genre'),
        items: const [
          DropdownMenuItem<Gender>(
              value: Gender.femme, child: Text('Femme')),
          DropdownMenuItem<Gender>(
              value: Gender.homme, child: Text('Homme')),
          DropdownMenuItem<Gender>(
              value: Gender.autre, child: Text('Autre')),
        ],
        onChanged: (Gender? v) => setState(() => _gender = v),
      );

  Widget _countryField() => DropdownButtonFormField<String>(
        initialValue: _country,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.public_outlined, size: 20),
        ),
        items: _countries
            .map((String c) =>
                DropdownMenuItem<String>(value: c, child: Text(c)))
            .toList(),
        onChanged: (String? v) => setState(() => _country = v ?? _country),
      );

  Widget _familyStatusField() => DropdownButtonFormField<String>(
        initialValue: _familyStatus.isEmpty ? null : _familyStatus,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.diversity_3_outlined, size: 20),
        ),
        hint: const Text('Situation familiale'),
        items: _familyStatuses
            .map((String c) =>
                DropdownMenuItem<String>(value: c, child: Text(c)))
            .toList(),
        onChanged: (String? v) => setState(() => _familyStatus = v ?? ''),
      );

  Widget _roleField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return TextFormField(
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
      ),
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _religionField() => DropdownButtonFormField<String>(
        initialValue: _religion.isEmpty ? null : _religion,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.auto_awesome_outlined, size: 20),
        ),
        hint: const Text('Rapport à la religion'),
        items: _religions
            .map((String c) =>
                DropdownMenuItem<String>(value: c, child: Text(c)))
            .toList(),
        onChanged: (String? v) => setState(() => _religion = v ?? ''),
      );

  Widget _childrenSwitch() => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _hasChildren,
        onChanged: (bool v) => setState(() => _hasChildren = v),
        title: const Text('J’ai des enfants'),
        activeThumbColor: AppColors.red,
      );

  Widget _wantsChildrenField() => DropdownButtonFormField<String>(
        initialValue: _wantsChildren,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.family_restroom_outlined, size: 20),
        ),
        items: _wantsChildrenOpts
            .map((MapEntry<String, String> e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                ))
            .toList(),
        onChanged: (String? v) =>
            setState(() => _wantsChildren = v ?? 'pas_sur'),
      );

  Widget _charteTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: CheckboxListTile(
        value: value,
        onChanged: (bool? v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.red,
        title: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
