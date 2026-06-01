import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/models/entity/learning_history_entity.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/service/personalization_service.dart';
import 'package:intl/intl.dart';

class LearningHistoryPage extends StatefulWidget {
  const LearningHistoryPage({super.key});

  @override
  State<LearningHistoryPage> createState() => _LearningHistoryPageState();
}

class _LearningHistoryPageState extends State<LearningHistoryPage> {
  late final String _userKey;
  late final LearningHistoryRepository _historyRepo;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  List<DateTime> _activeDates = [];
  List<LearningHistoryEntity> _wordsStudied = [];
  bool _isLoadingHistory = false;
  bool _isLoadingActiveDates = false;

  // Personalization settings
  int _dailyGoal = 20;

  @override
  void initState() {
    super.initState();
    _userKey = UserSession.instance.userKey;
    _historyRepo = context.read<LearningHistoryRepository>();

    _initPersonalization();
    _loadActiveDates();
    _loadHistoryForSelectedDate();
  }

  Future<void> _initPersonalization() async {
    await PersonalizationService.instance.init();
    setState(() {
      _dailyGoal = PersonalizationService.instance.getDailyWordTarget();
    });
  }

  Future<void> _loadActiveDates() async {
    setState(() => _isLoadingActiveDates = true);
    try {
      final dates = await _historyRepo.getActiveDates(userKey: _userKey);
      setState(() {
        _activeDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toList();
      });
    } catch (e) {
      debugPrint('Error loading active dates: $e');
    } finally {
      setState(() => _isLoadingActiveDates = false);
    }
  }

  Future<void> _loadHistoryForSelectedDate() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _historyRepo.getHistoryByDate(
        userKey: _userKey,
        date: _selectedDate,
        page: 1,
        pageSize: 100, // retrieve all for selected day
      );
      setState(() {
        _wordsStudied = history;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _onDateSelected(DateTime date) {
    if (date.isAfter(DateTime.now())) return; // cannot select future dates
    setState(() {
      _selectedDate = date;
    });
    _loadHistoryForSelectedDate();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    if (next.isAfter(DateTime.now()) && next.month != DateTime.now().month) return;
    setState(() {
      _focusedMonth = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F8FE),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPersonalizationBanner(),
                        const SizedBox(height: 20),
                        _buildCalendarCard(),
                        const SizedBox(height: 24),
                        _buildStatsSummary(),
                        const SizedBox(height: 24),
                        Text(
                          'Vocabulary Reviewed (${_wordsStudied.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'STUDY HISTORY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // balance back button
        ],
      ),
    );
  }

  Widget _buildPersonalizationBanner() {
    final correctCount = _wordsStudied.where((w) => w.isCorrect ?? false).length;
    final progress = _wordsStudied.isEmpty ? 0.0 : _wordsStudied.length / _dailyGoal;
    final displayProgress = progress > 1.0 ? 1.0 : progress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Personalized Target',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Goal: $_dailyGoal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: displayProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_wordsStudied.length} / $_dailyGoal words studied today',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(displayProgress * 100).toInt()}% completed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 16),
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthName = DateFormat('MMMM yyyy').format(_focusedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
          onPressed: _previousMonth,
        ),
        Text(
          monthName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;

    final List<Widget> dayCells = [];

    // Add empty spacer cells for alignment
    for (int i = 1; i < firstDayWeekday; i++) {
      dayCells.add(const SizedBox.shrink());
    }

    final today = DateTime.now();

    for (int day = 1; day <= daysInMonth; day++) {
      final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = cellDate.year == _selectedDate.year &&
          cellDate.month == _selectedDate.month &&
          cellDate.day == _selectedDate.day;

      final isToday = cellDate.year == today.year &&
          cellDate.month == today.month &&
          cellDate.day == today.day;

      final hasHistory = _activeDates.any((d) =>
          d.year == cellDate.year &&
          d.month == cellDate.month &&
          d.day == cellDate.day);

      final isFuture = cellDate.isAfter(today);

      dayCells.add(
        GestureDetector(
          onTap: isFuture ? null : () => _onDateSelected(cellDate),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF10B981) // selected glowing emerald green
                    : isToday
                        ? const Color(0xFFEFF6FF)
                        : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isFuture
                          ? const Color(0xFFCBD5E1)
                          : isSelected
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF334155),
                    ),
                  ),
                  if (hasHistory && !isSelected)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: dayCells.length,
      itemBuilder: (context, index) => dayCells[index],
    );
  }

  Widget _buildStatsSummary() {
    final correctCount = _wordsStudied.where((w) => w.isCorrect ?? false).length;
    final accuracy = _wordsStudied.isEmpty ? 0 : ((correctCount / _wordsStudied.length) * 100).toInt();

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Reviewed',
            '${_wordsStudied.length}',
            'vocabulary cards',
            const Color(0xFF3B82F6),
            Icons.menu_book,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Accuracy',
            '$accuracy%',
            'correct rate',
            const Color(0xFF10B981),
            Icons.offline_bolt,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_wordsStudied.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _wordsStudied.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _wordsStudied[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(LearningHistoryEntity item) {
    final statusColor = item.isCorrect! ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.word ?? '',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.sessionType ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.meaning ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.isCorrect! ? 'Correct' : 'Again',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Repetition: ${item.wordLevelSnapshot}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text(
              '🌱',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            const Text(
              'No study sessions logged today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Personalized companion is waiting for you.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.maybePop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 0,
              ),
              child: const Text(
                'Start Studying Now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
