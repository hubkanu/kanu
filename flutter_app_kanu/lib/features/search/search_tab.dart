import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/member_repository.dart';
import '../../models/member.dart';
import '../../models/search_filters.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/search_controller.dart';

/// Onglet de recherche de profils avec filtres.
class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Member? member = ref.read(authControllerProvider).member;
      if (member != null) {
        ref.read(searchControllerProvider.notifier).search(member);
      }
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return;
    FocusScope.of(context).unfocus();
    final SearchNotifier notifier = ref.read(searchControllerProvider.notifier);
    notifier.updateFilters(
      ref.read(searchControllerProvider).filters.copyWith(query: _query.text),
    );
    await notifier.search(self);
  }

  Future<void> _openFilters() async {
    final SearchNotifier notifier =
        ref.read(searchControllerProvider.notifier);
    final SearchFilters? result = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: ref.read(searchControllerProvider).filters),
    );
    if (result == null || !mounted) return;
    notifier.updateFilters(result);
    final Member? self = ref.read(authControllerProvider).member;
    if (self != null) await notifier.search(self);
  }

  @override
  Widget build(BuildContext context) {
    final SearchState provider = ref.watch(searchControllerProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _run(),
                    decoration: InputDecoration(
                      hintText: 'Prénom, ville, métier…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _query.clear();
                                _run();
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _filterButton(provider),
              ],
            ),
          ),
          if (!provider.filters.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _filterSummary(provider.filters),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(child: _body(provider)),
        ],
      ),
    );
  }

  Widget _filterButton(SearchState provider) {
    return Stack(
      children: [
        IconButton.filledTonal(
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Filtres',
        ),
        if (!provider.filters.isEmpty)
          const Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(radius: 4, backgroundColor: AppColors.red),
          ),
      ],
    );
  }

  Widget _body(SearchState provider) {
    if (provider.loading) return const LoadingView(label: 'Recherche…');
    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: _run,
      );
    }
    if (provider.isEmpty) {
      return EmptyStateView(
        title: 'Aucun profil trouvé',
        message: 'Élargissez vos critères pour découvrir davantage de membres.',
        icon: Icons.search_off_rounded,
        action: KanuButton(
          label: 'Modifier les filtres',
          expand: false,
          variant: KanuButtonVariant.outline,
          onPressed: _openFilters,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: provider.results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int i) =>
          _profileCard(context, provider.results[i]),
    );
  }

  Widget _profileCard(BuildContext context, ProfileMatch match) {
    final Member m = match.member;
    final List<String> chips = [
      if (m.age != null) '${m.age} ans',
      if (m.city.isNotEmpty) m.city,
      if (m.professionalField.isNotEmpty) m.professionalField,
    ];
    return KanuCard(
      onTap: () => context.push('/membre/${m.id}'),
      child: Row(
        children: [
          MemberAvatar(member: m, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.fullName,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  chips.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (match.score != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Compatibilité ${match.score}%',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.rose),
                  ),
                ],
              ],
            ),
          ),
          if (match.score != null)
            ScoreRing(score: match.score!, size: 48, showLabel: true),
        ],
      ),
    );
  }

  String _filterSummary(SearchFilters f) {
    final List<String> parts = [];
    parts.add('${f.minAge}-${f.maxAge} ans');
    if (f.gender != null) parts.add(genderLabel(f.gender!));
    if (f.city.isNotEmpty) parts.add(f.city);
    if (f.religion.isNotEmpty) parts.add(f.religion);
    if (f.hasChildren != null) {
      parts.add(f.hasChildren! ? 'Avec enfants' : 'Sans enfant');
    }
    return parts.join('  ·  ');
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final SearchFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RangeValues _age;
  late TextEditingController _city;
  Gender? _gender;
  String _religion = '';
  bool? _hasChildren;

  @override
  void initState() {
    super.initState();
    _age = RangeValues(
      widget.initial.minAge.toDouble(),
      widget.initial.maxAge.toDouble(),
    );
    _city = TextEditingController(text: widget.initial.city);
    _gender = widget.initial.gender;
    _religion = widget.initial.religion;
    _hasChildren = widget.initial.hasChildren;
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtres', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Âge : ${_age.start.round()} – ${_age.end.round()} ans',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            RangeSlider(
              values: _age,
              min: 30,
              max: 75,
              divisions: 45,
              labels: RangeLabels(
                _age.start.round().toString(),
                _age.end.round().toString(),
              ),
              onChanged: (RangeValues v) => setState(() => _age = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _city,
              decoration: const InputDecoration(
                labelText: 'Ville',
                prefixIcon: Icon(Icons.location_city_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender?>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Genre recherché',
                prefixIcon: Icon(Icons.wc_outlined, size: 20),
              ),
              items: const [
                DropdownMenuItem<Gender?>(
                    value: null, child: Text('Tous')),
                DropdownMenuItem<Gender?>(
                    value: Gender.femme, child: Text('Femmes')),
                DropdownMenuItem<Gender?>(
                    value: Gender.homme, child: Text('Hommes')),
              ],
              onChanged: (Gender? v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _religion.isEmpty ? '' : _religion,
              decoration: const InputDecoration(
                labelText: 'Rapport à la religion',
                prefixIcon: Icon(Icons.auto_awesome_outlined, size: 20),
              ),
              items: const [
                DropdownMenuItem<String>(value: '', child: Text('Indifférent')),
                DropdownMenuItem<String>(
                    value: 'Pratiquant', child: Text('Pratiquant(e)')),
                DropdownMenuItem<String>(
                    value: 'Croyant', child: Text('Croyant(e)')),
                DropdownMenuItem<String>(
                    value: 'Athée', child: Text('Athée')),
              ],
              onChanged: (String? v) => setState(() => _religion = v ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _hasChildren == null
                  ? 'all'
                  : (_hasChildren! ? 'yes' : 'no'),
              decoration: const InputDecoration(
                labelText: 'Enfants',
                prefixIcon: Icon(Icons.child_care_outlined, size: 20),
              ),
              items: const [
                DropdownMenuItem<String>(value: 'all', child: Text('Peu importe')),
                DropdownMenuItem<String>(value: 'yes', child: Text('Avec enfants')),
                DropdownMenuItem<String>(value: 'no', child: Text('Sans enfant')),
              ],
              onChanged: (String? v) => setState(() {
                _hasChildren = v == 'all' ? null : v == 'yes';
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: KanuButton(
                    label: 'Réinitialiser',
                    variant: KanuButtonVariant.outline,
                    onPressed: () {
                      Navigator.of(context).pop(const SearchFilters());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KanuButton(
                    label: 'Appliquer',
                    onPressed: () {
                      Navigator.of(context).pop(
                        widget.initial.copyWith(
                          minAge: _age.start.round(),
                          maxAge: _age.end.round(),
                          city: _city.text,
                          gender: _gender,
                          clearGender: _gender == null,
                          religion: _religion,
                          hasChildren: _hasChildren,
                          clearChildren: _hasChildren == null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
