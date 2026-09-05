import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../commons/app_colors.dart';
import '../../../commons/enums.dart';
import '../../../database/app_db.dart';
import '../test_cubit.dart' hide TimerMode, WordFilter, QuestionType;
import '../widgets/app_bar_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/card_widget.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  static const _questionCounts = [5, 10, 15, 20, 30];

  static const _totalTimes = [
    (label: '5 phút',  s: 300),
    (label: '10 phút', s: 600),
    (label: '15 phút', s: 900),
    (label: '20 phút', s: 1200),
    (label: '30 phút', s: 1800),
  ];

  static const _perWordTimes = [
    (label: '10 giây', s: 10),
    (label: '15 giây', s: 15),
    (label: '30 giây', s: 30),
    (label: '45 giây', s: 45),
    (label: '60 giây', s: 60),
  ];

  Widget _buildTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.kBlueBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.kBlue : AppColors.kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.kBlue : Colors.grey),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.kBlue : Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? const Color(0xFF3B82F6) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeSelector({
    required QuestionType type,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            icon: Icons.shuffle_rounded,
            title: 'Hỗn hợp',
            subtitle: 'Xáo trộn ngẫu nhiên',
            selected: type == QuestionType.random,
            onTap: () {  },
          ),
        ),
      ],
    );
  }

  Widget _buildWordFilterSelector({
    required WordFilter filter,
    required ValueChanged<WordFilter> onChanged,
  }) {
    return Row(
      children: WordFilter.values.map((f) {
        final label = switch (f) {
          WordFilter.all        => 'Tất cả',
          WordFilter.learned    => '⭐ Đã thuộc',
          WordFilter.notLearned => '📖 Chưa thuộc',
        };
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _buildChip(
            label: label,
            selected: filter == f,
            onTap: () => onChanged(f),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagFilterSelector({
    required List<Tag> allTags,
    required List<int> selectedTagIds,
    required ValueChanged<int> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allTags.map((tag) {
        final sel = selectedTagIds.contains(tag.id);
        return _buildChip(
          label: tag.tagName,
          selected: sel,
          onTap: () => onToggle(tag.id),
        );
      }).toList(),
    );
  }

  String _langLabel(String lang) => switch (lang) {
    'ja' => '🇯🇵 Tiếng Nhật',
    'en' => '🇬🇧 Tiếng Anh',
    'zh' => '🇨🇳 Tiếng Trung',
    'ko' => '🇰🇷 Tiếng Hàn',
    _    => lang.toUpperCase(),
  };

  Widget _buildLanguageSelector({
    required List<String> languages,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          label: 'Tất cả',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        ...languages.map((l) => _buildChip(
          label: _langLabel(l),
          selected: selected == l,
          onTap: () => onChanged(l),
        )),
      ],
    );
  }

  Widget _buildTimerToggle({
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.kBorder)),
      child: Row(
        children: [
          Icon(enabled ? Icons.timer_rounded : Icons.timer_off_outlined,
              color: enabled ? AppColors.kBlue : Colors.grey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enabled ? 'Đang bật giới hạn giờ' : 'Không giới hạn thời gian',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Switch.adaptive(
              value: enabled, activeColor: AppColors.kBlue, onChanged: onToggle),
        ],
      ),
    );
  }

  Widget _buildTimerModeRow({
    required TimerMode mode,
    required ValueChanged<TimerMode> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            icon: Icons.access_time_rounded,
            title: 'Thời gian tổng',
            subtitle: 'Một mốc cho cả bài',
            selected: mode == TimerMode.total,
            onTap: () => onChanged(TimerMode.total),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTypeCard(
            icon: Icons.replay_circle_filled_rounded,
            title: 'Mỗi từ',
            subtitle: 'Reset sau mỗi câu',
            selected: mode == TimerMode.perWord,
            onTap: () => onChanged(TimerMode.perWord),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kSurface,
      appBar: SimpleAppBar('Kiểm tra từ vựng'),
      body: BlocBuilder<TestCubit, TestState>(
        builder: (ctx, s) {
          final c = ctx.read<TestCubit>();
          final cfg = s.config;
          final timeOpts =
          cfg.timerMode == TimerMode.total ? _totalTimes : _perWordTimes;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                GradientCard(
                  child: Row(children: [
                    const Icon(Icons.school_rounded,
                        color: Colors.white, size: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Tuỳ chỉnh bài kiểm tra',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 3),
                          Text('Chọn từ vựng, loại câu hỏi và thời gian',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                _sectionTitle('Bộ lọc từ vựng', Icons.filter_list_rounded),
                const SizedBox(height: 10),
                _buildWordFilterSelector(
                  filter: cfg.wordFilter,
                  onChanged: c.setWordFilter,
                ),
                const SizedBox(height: 16),

                if (s.allTags.isNotEmpty) ...[
                  _sectionTitle('Lọc theo đơn vị / tag', Icons.label_outline),
                  const SizedBox(height: 10),
                  _buildTagFilterSelector(
                    allTags: s.allTags,
                    selectedTagIds: cfg.selectedTagIds,
                    onToggle: c.toggleTagFilter,
                  ),
                  const SizedBox(height: 16),
                ],

                if (s.availableLanguages.isNotEmpty) ...[
                  _sectionTitle('Ngôn ngữ', Icons.language_rounded),
                  const SizedBox(height: 10),
                  _buildLanguageSelector(
                    languages: s.availableLanguages,
                    selected: cfg.selectedLanguage,
                    onChanged: c.setLanguageFilter,
                  ),
                  const SizedBox(height: 22),
                ],

                _sectionTitle('Số câu hỏi', Icons.format_list_numbered_rounded),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _questionCounts
                      .map((n) => _buildChip(
                    label: '$n câu',
                    selected: cfg.questionCount == n,
                    onTap: () => c.setQuestionCount(n),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 22),

                _sectionTitle('Giới hạn thời gian', Icons.timer_outlined),
                const SizedBox(height: 10),
                _buildTimerToggle(
                    enabled: cfg.enableTimer, onToggle: c.toggleTimer),

                if (cfg.enableTimer) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Chế độ đếm giờ', Icons.tune_outlined),
                  const SizedBox(height: 10),
                  _buildTimerModeRow(
                      mode: cfg.timerMode, onChanged: c.setTimerMode),
                  const SizedBox(height: 16),
                  _sectionTitle(
                    cfg.timerMode == TimerMode.total
                        ? 'Tổng thời gian'
                        : 'Thời gian mỗi từ',
                    Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: timeOpts
                        .map((o) => _buildChip(
                      label: o.label,
                      selected: cfg.timeLimitSeconds == o.s,
                      onTap: () => c.setTimeLimit(o.s),
                    ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 32),

                if (s.loadStatus == LOADSTATUS.FAILED && s.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildErrorBanner(s.errorMessage ?? ''),
                  ),
                buildPrimaryButton(
                  label: 'Bắt đầu kiểm tra',
                  icon: Icons.arrow_forward_rounded,
                  loading: s.loadStatus == LOADSTATUS.LOADING,
                  onTap: () => ctx.read<TestCubit>().startTest(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.kBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.kBlue : AppColors.kBorder,
              width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [
            BoxShadow(
                color: AppColors.kBlue.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54)),
      ),
    );
  }


  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: AppColors.kRed)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.kBlue),
        const SizedBox(width: 7),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
      ],
    );
  }
}