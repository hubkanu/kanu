import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../models/questionnaire.dart';
import '../../shared/widgets/kanu_button.dart';
import '../../shared/widgets/kanu_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/state_views.dart';
import '../../state/auth_controller.dart';
import '../../state/providers.dart';

/// Questionnaire de compatibilité, section par section.
class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final Map<String, dynamic> _answers = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) {
      setState(() => _loading = false);
      return;
    }
    final Questionnaire? q =
        await ref.read(questionnaireRepositoryProvider).loadFor(self.id);
    if (!mounted) return;
    setState(() {
      if (q != null) _answers.addAll(q.answers);
      _loading = false;
    });
  }

  double get _progress {
    if (QuestionnaireCatalog.total == 0) return 0;
    final int answered = _answers.keys
        .where((String k) => _answers[k] != null && _answers[k].toString().isNotEmpty)
        .length;
    return (answered / QuestionnaireCatalog.total).clamp(0, 1);
  }

  Future<void> _save() async {
    final AuthController auth = ref.read(authControllerProvider.notifier);
    final Member? self = ref.read(authControllerProvider).member;
    if (self == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(questionnaireRepositoryProvider).save(self, _answers);
      await auth.markQuestionnaireCompleted();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci ! Votre questionnaire est enregistré.'),
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Questionnaire')),
        body: const LoadingView(label: 'Chargement de vos réponses…'),
      );
    }

    final Map<String, List<Question>> sections =
        QuestionnaireCatalog.bySection;

    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire')),
      body: Column(
        children: [
          _progressHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                for (final MapEntry<String, List<Question>> section
                    in sections.entries)
                  ..._section(context, section.key, section.value),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: KanuButton(
                label: 'Enregistrer mes réponses',
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressHeader(BuildContext context) {
    final int percent = (_progress * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Progression',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '$percent %',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.rose),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<Question> questions,
  ) {
    return [
      SectionHeader(title: title, overline: 'Compatibilité'),
      ...questions.map(
        (Question q) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: _questionCard(context, q),
        ),
      ),
    ];
  }

  Widget _questionCard(BuildContext context, Question q) {
    return KanuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (q.type == QuestionType.yesNo)
            _yesNo(q)
          else if (q.type == QuestionType.multi)
            _multi(q)
          else
            _single(q),
        ],
      ),
    );
  }

  Widget _single(Question q) {
    final String? value = _answers[q.key]?.toString();
    return RadioGroup<String>(
      groupValue: value,
      onChanged: (String? v) => setState(() => _answers[q.key] = v),
      child: Column(
        children: q.options.map((QuestionOption o) {
          return RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: o.value,
            activeColor: AppColors.red,
            title: Text(
              o.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _multi(Question q) {
    final List<String> selected = _selectedList(q.key);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: q.options.map((QuestionOption o) {
        final bool isSelected = selected.contains(o.value);
        return FilterChip(
          label: Text(o.label),
          selected: isSelected,
          onSelected: (bool v) {
            setState(() {
              final List<String> list = _selectedList(q.key);
              if (v) {
                list.add(o.value);
              } else {
                list.remove(o.value);
              }
              _answers[q.key] = list;
            });
          },
          selectedColor: AppColors.red.withValues(alpha: 0.2),
          checkmarkColor: AppColors.rose,
        );
      }).toList(),
    );
  }

  Widget _yesNo(Question q) {
    final bool? value = _answers[q.key] == null
        ? null
        : _answers[q.key] == true || _answers[q.key] == 'oui';
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text('Oui', textAlign: TextAlign.center),
            ),
            selected: value == true,
            onSelected: (_) => setState(() => _answers[q.key] = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const SizedBox(
              width: double.infinity,
              child: Text('Non', textAlign: TextAlign.center),
            ),
            selected: value == false,
            onSelected: (_) => setState(() => _answers[q.key] = false),
          ),
        ),
      ],
    );
  }

  List<String> _selectedList(String key) {
    final dynamic value = _answers[key];
    if (value is List) return value.map((e) => e.toString()).toList();
    return <String>[];
  }
}
