import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/enums.dart';
import '../../../generated/l10n.dart';
import '../../../service/tts_service.dart';
import '../../daily_review/widgets/daily_review_banner.dart';
import '../test_cubit.dart';
import '../widgets/config/config_chip.dart';
import '../widgets/config/config_section.dart';
import '../widgets/config/start_bar.dart';
import '../widgets/config/test_kind_card.dart';
import '../widgets/ui_test_components.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with WidgetsBindingObserver {
  static const _muted = TextStyle(fontSize: 12, color: AppColors.xoayPaperDim);

  TestCubit get _cubit => context.read<TestCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the voice installer: a new voice may be there.
    if (state == AppLifecycleState.resumed) _cubit.refreshVoices();
  }

  @override
  Widget build(BuildContext context) {
    return TestScreenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: testScreenAppBar(title: Text(S.of(context).test_config_title)),
        body: BlocBuilder<TestCubit, TestState>(
          buildWhen: (p, c) =>
              p.config != c.config ||
              p.allWords != c.allWords ||
              p.voiceLanguages != c.voiceLanguages ||
              p.loadStatus != c.loadStatus ||
              p.errorMessage != c.errorMessage,
          builder: (context, state) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DailyReviewBanner(),
                      const SizedBox(height: 20),
                      _buildKinds(state),
                      const SizedBox(height: 24),
                      _buildScope(state),
                      const SizedBox(height: 24),
                      _buildCount(state),
                      const SizedBox(height: 24),
                      _buildTime(state),
                      if (state.loadStatus == LOADSTATUS.FAILED &&
                          (state.errorMessage ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildError(state.errorMessage ?? ''),
                      ],
                    ],
                  ),
                ),
              ),
              StartBar(
                label: _startLabel(state),
                enabled: state.matchingWordCount > 0,
                loading: state.loadStatus == LOADSTATUS.LOADING,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _cubit.startTest();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Kinds ─────────────────────────────────────────────────────────────────

  Widget _buildKinds(TestState state) {
    final kinds = state.config.kinds;
    final noVoice = !state.hasVoiceForScope;
    Widget card(TestKind kind) {
      final dimmed = kind == TestKind.listening && noVoice;
      return TestKindCard(
        kind: kind,
        selected: kinds.contains(kind),
        dimmed: dimmed,
        footer: dimmed ? _buildInstallVoice : null,
        onTap: () {
          if (kinds.length == 1 && kinds.contains(kind)) {
            HapticFeedback.lightImpact();
          }
          _cubit.toggleKind(kind);
        },
      );
    }

    Widget row(TestKind left, TestKind right) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card(left)),
              const SizedBox(width: 10),
              Expanded(child: card(right)),
            ],
          ),
        );

    return ConfigSection(
      title: S.of(context).test_section_kinds,
      icon: Icons.category_outlined,
      trailing: Text(S.of(context).test_section_kinds_hint, style: _muted),
      child: Column(
        children: [
          row(TestKind.choice, TestKind.typing),
          const SizedBox(height: 10),
          row(TestKind.listening, TestKind.trueFalse),
        ],
      ),
    );
  }

  Widget get _buildInstallVoice => GestureDetector(
        onTap: () => context.read<TtsService>().openVoiceDataInstaller(),
        child: Text(
          S.of(context).test_install_voice,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.xoayCyan,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.xoayCyan,
          ),
        ),
      );

  // ─── Scope ─────────────────────────────────────────────────────────────────

  Widget _buildScope(TestState state) {
    final cfg = state.config;
    final count = state.matchingWordCount;
    final short = count < cfg.questionCount;
    return ConfigSection(
      title: S.of(context).test_section_scope,
      icon: Icons.filter_list_rounded,
      trailing: Text(
        S.of(context).test_matching_words(count),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: short ? AppColors.xoayGold : AppColors.xoayCyan,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in WordFilter.values)
                ConfigChip(
                  label: _filterLabel(filter),
                  selected: cfg.wordFilter == filter,
                  onTap: () => _cubit.setWordFilter(filter),
                ),
            ],
          ),
          if (state.allTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(S.of(context).test_section_tags, style: _muted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in state.allTags)
                  ConfigChip(
                    label: tag.tagName,
                    selected: cfg.selectedTagIds.contains(tag.id),
                    onTap: () => _cubit.toggleTagFilter(tag.id),
                  ),
              ],
            ),
          ],
          if (state.availableLanguages.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(S.of(context).test_section_language, style: _muted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ConfigChip(
                  label: S.of(context).test_language_all,
                  selected: cfg.selectedLanguage == null,
                  onTap: () => _cubit.setLanguageFilter(null),
                ),
                for (final language in state.availableLanguages)
                  ConfigChip(
                    label: _languageLabel(language),
                    selected: cfg.selectedLanguage == language,
                    onTap: () => _cubit.setLanguageFilter(language),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _filterLabel(WordFilter filter) => switch (filter) {
        WordFilter.all => S.of(context).test_filter_all,
        WordFilter.learned => S.of(context).test_filter_learned,
        WordFilter.notLearned => S.of(context).test_filter_not_learned,
      };

  String _languageLabel(String code) => switch (code) {
        'ja' => S.of(context).test_language_ja,
        'en' => S.of(context).test_language_en,
        'zh' => S.of(context).test_language_zh,
        'ko' => S.of(context).test_language_ko,
        'vi' => S.of(context).test_language_vi,
        _ => code.toUpperCase(),
      };

  // ─── Count ─────────────────────────────────────────────────────────────────

  Widget _buildCount(TestState state) {
    return ConfigSection(
      title: S.of(context).test_section_count,
      icon: Icons.format_list_numbered_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in TestConfig.questionCountOptions)
            ConfigChip(
              label: S.of(context).test_question_count(n),
              selected: state.config.questionCount == n,
              onTap: () => _cubit.setQuestionCount(n),
            ),
        ],
      ),
    );
  }

  // ─── Time ──────────────────────────────────────────────────────────────────

  Widget _buildTime(TestState state) {
    final cfg = state.config;
    final perQuestion = cfg.timerMode == TimerMode.perWord;
    final options = perQuestion
        ? TestConfig.perQuestionTimeOptions
        : TestConfig.totalTimeOptions;
    return ConfigSection(
      title: S.of(context).test_section_time,
      icon: Icons.timer_outlined,
      trailing: Switch.adaptive(
        value: cfg.enableTimer,
        activeColor: AppColors.xoayGold,
        activeTrackColor: AppColors.xoayGold.withValues(alpha: 0.45),
        inactiveThumbColor: AppColors.xoayPaper,
        inactiveTrackColor: AppColors.xoayLine,
        onChanged: _cubit.toggleTimer,
      ),
      child: !cfg.enableTimer
          ? Text(S.of(context).test_timer_off, style: _muted)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ConfigChip(
                      label: S.of(context).test_timer_total,
                      selected: !perQuestion,
                      onTap: () => _cubit.setTimerMode(TimerMode.total),
                    ),
                    ConfigChip(
                      label: S.of(context).test_timer_per_question,
                      selected: perQuestion,
                      onTap: () => _cubit.setTimerMode(TimerMode.perWord),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  perQuestion
                      ? S.of(context).test_timer_per_question_desc
                      : S.of(context).test_timer_total_desc,
                  style: _muted,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final seconds in options)
                      ConfigChip(
                        label: perQuestion
                            ? S.of(context).test_seconds(seconds)
                            : S.of(context).test_minutes(seconds ~/ 60),
                        selected: cfg.timeLimitSeconds == seconds,
                        onTap: () => _cubit.setTimeLimit(seconds),
                      ),
                  ],
                ),
                if (perQuestion && cfg.kinds.contains(TestKind.typing)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.xoayPaperDim),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(S.of(context).test_typing_double_time,
                            style: _muted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  // ─── Start / error ─────────────────────────────────────────────────────────

  String _startLabel(TestState state) {
    final cfg = state.config;
    final base = S
        .of(context)
        .test_start_summary(state.plannedQuestionCount, cfg.kinds.length);
    if (!cfg.enableTimer) return base;
    final time = cfg.timerMode == TimerMode.total
        ? S.of(context).test_minutes(cfg.timeLimitSeconds ~/ 60)
        : S.of(context).test_time_per_question(cfg.timeLimitSeconds);
    return '$base · $time';
  }

  Widget _buildError(String message) {
    return TestScreenNote(
      icon: Icons.error_outline_rounded,
      color: AppColors.xoayMagenta,
      text: message,
    );
  }
}
