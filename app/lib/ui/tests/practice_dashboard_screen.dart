import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../services/question_service.dart';
import '../../core/theme.dart';
import 'category_practice_screen.dart';
import 'practice_screen.dart';

class PracticeDashboardScreen extends StatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  State<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends State<PracticeDashboardScreen> {
  List<Category> _categories = [];
  List<Question> _allQuestions = [];
  Map<String, int> _categoryQuestionCounts = {};
  bool _loading = true;
  UserStats? _userStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final categories = await QuestionService.fetchCategories();
      final questions = await QuestionService.fetchQuestions(limit: 100);
      final stats = await QuestionService.fetchUserStats();

      // Calculate question counts per category
      final counts = <String, int>{};
      for (var q in questions) {
        counts[q.categorySlug] = (counts[q.categorySlug] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _allQuestions = questions;
          _categoryQuestionCounts = counts;
          _userStats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  int _getQuestionCountByDifficulty(String difficulty) {
    return _allQuestions.where((q) => q.difficulty == difficulty).length;
  }

  List<Question> _getQuestionsByType(String type) {
    return _allQuestions.where((q) => q.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Practice Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── User Stats Section ───
                    if (_userStats != null) ...[
                      const Text('Your Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.accent.withValues(alpha: 0.2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(label: 'Attempted', value: _userStats!.totalAttempted.toString(), icon: Icons.check_circle_outline),
                            _StatItem(label: 'Passed', value: _userStats!.testsPassed.toString(), icon: Icons.thumb_up),
                            _StatItem(label: 'Accuracy', value: '${_userStats!.accuracy.toStringAsFixed(1)}%', icon: Icons.trending_up),
                            _StatItem(label: 'Streak', value: _userStats!.streak.toString(), icon: Icons.local_fire_department),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Quick Access Section ───
                    const Text('Quick Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAccessButton(
                            label: 'All Questions',
                            icon: Icons.library_books_rounded,
                            count: _allQuestions.length.toString(),
                            color: AppTheme.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PracticeScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAccessButton(
                            label: 'By Difficulty',
                            icon: Icons.filter_list_rounded,
                            count: '3 Levels',
                            color: AppTheme.accent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PracticeScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Difficulty Breakdown Section ───
                    const Text('Difficulty Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _DifficultyBar(
                          difficulty: 'EASY',
                          count: _getQuestionCountByDifficulty('EASY'),
                          total: _allQuestions.length,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(height: 10),
                        _DifficultyBar(
                          difficulty: 'MEDIUM',
                          count: _getQuestionCountByDifficulty('MEDIUM'),
                          total: _allQuestions.length,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(height: 10),
                        _DifficultyBar(
                          difficulty: 'HARD',
                          count: _getQuestionCountByDifficulty('HARD'),
                          total: _allQuestions.length,
                          color: AppTheme.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Question Types Section ───
                    const Text('Question Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _QuestionTypeCard(
                          type: 'MCQ',
                          count: _getQuestionsByType('MCQ').length,
                          icon: Icons.radio_button_checked_rounded,
                          color: AppTheme.primary,
                        ),
                        _QuestionTypeCard(
                          type: 'LOGICAL',
                          count: _getQuestionsByType('LOGICAL').length,
                          icon: Icons.psychology_rounded,
                          color: const Color(0xFF9C27B0),
                        ),
                        _QuestionTypeCard(
                          type: 'CODING',
                          count: _getQuestionsByType('CODING').length,
                          icon: Icons.code_rounded,
                          color: const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Categories Section ───
                    const Text('Practice by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
                        final count = _categoryQuestionCounts[cat.slug] ?? 0;
                        return GestureDetector(
                          onTap: count > 0
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPracticeScreen(category: cat),
                                    ),
                                  )
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: count > 0 ? AppTheme.surface : AppTheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: count > 0 ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.surfaceLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (cat.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          cat.description,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count Q',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (count > 0)
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBar extends StatelessWidget {
  final String difficulty;
  final int count;
  final int total;
  final Color color;

  const _DifficultyBar({
    required this.difficulty,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(difficulty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('$count / $total', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: AppTheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _QuestionTypeCard extends StatelessWidget {
  final String type;
  final int count;
  final IconData icon;
  final Color color;

  const _QuestionTypeCard({
    required this.type,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('$count Q', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
