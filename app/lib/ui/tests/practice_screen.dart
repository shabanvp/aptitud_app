import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question.dart';
import '../../services/question_service.dart';
import '../../providers/game_state_provider.dart';
import '../../core/theme.dart';
import 'test_attempt_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<Question> _allQuestions = [];
  List<Category> _categories = [];
  List<Question> _filteredQuestions = [];
  bool _loading = true;
  String _selectedDifficulty = 'ALL';
  String _selectedCategory = 'ALL';
  String _selectedType = 'ALL';
  int _currentPage = 0;
  final int _pageSize = 15;
  bool _startingQuiz = false;

  final List<String> _difficulties = ['ALL', 'EASY', 'MEDIUM', 'HARD'];
  final List<String> _types = ['ALL', 'MCQ', 'LOGICAL', 'CODING'];

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

      if (mounted) {
        setState(() {
          _categories = categories;
          _allQuestions = questions;
          _applyFilters();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _applyFilters() {
    _filteredQuestions = _allQuestions.where((q) {
      bool diffMatch =
          _selectedDifficulty == 'ALL' || q.difficulty == _selectedDifficulty;
      bool catMatch =
          _selectedCategory == 'ALL' || q.categorySlug == _selectedCategory;
      bool typeMatch = _selectedType == 'ALL' || q.type == _selectedType;
      return diffMatch && catMatch && typeMatch;
    }).toList();
    _currentPage = 0;
  }

  Future<void> _startQuizFromQuestion(Question question) async {
    if (_startingQuiz) return;
    setState(() => _startingQuiz = true);

    final questions = await QuestionService.fetchQuestions(
      categorySlug: question.categorySlug.isNotEmpty
          ? question.categorySlug
          : null,
      difficulty: question.difficulty.isNotEmpty ? question.difficulty : null,
      limit: 10,
    );

    if (!mounted) return;
    setState(() => _startingQuiz = false);

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load quiz questions. Please try again.'),
        ),
      );
      return;
    }

    final uniqueQuestions = <String, Question>{};
    for (final q in questions) {
      uniqueQuestions[q.id] = q;
    }

    final quizQuestions = uniqueQuestions.values.toList();
    if (!quizQuestions.any((q) => q.id == question.id)) {
      quizQuestions.insert(0, question);
    }
    while (quizQuestions.length > 10) {
      quizQuestions.removeLast();
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestAttemptScreen(questions: quizQuestions),
      ),
    );

    if (mounted) {
      final gameState = Provider.of<GameStateProvider>(context, listen: false);
      await gameState.refreshStats();
      _loadData();
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'EASY':
        return AppTheme.secondary;
      case 'HARD':
        return AppTheme.error;
      default:
        return AppTheme.accent;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'LOGICAL':
        return const Color(0xFF9C27B0);
      case 'CODING':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.primary;
    }
  }

  List<Question> _getPaginatedQuestions() {
    final startIdx = _currentPage * _pageSize;
    final endIdx = startIdx + _pageSize;
    return _filteredQuestions.length > endIdx
        ? _filteredQuestions.sublist(startIdx, endIdx)
        : _filteredQuestions.sublist(startIdx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Practice Arena',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                // ─── Quick Stats Section ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatsCard(
                          icon: Icons.library_books_rounded,
                          label: 'Total',
                          value: _allQuestions.length.toString(),
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatsCard(
                          icon: Icons.category_rounded,
                          label: 'Categories',
                          value: _categories.length.toString(),
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatsCard(
                          icon: Icons.search_rounded,
                          label: 'Found',
                          value: _filteredQuestions.length.toString(),
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Filters Section ───
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    children: [
                      // Category Filter
                      SizedBox(
                        height: 40,
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'All Categories',
                              isSelected: _selectedCategory == 'ALL',
                              onTap: () {
                                setState(() {
                                  _selectedCategory = 'ALL';
                                  _applyFilters();
                                });
                              },
                            ),
                            ..._categories.map((cat) {
                              return _FilterChip(
                                label: cat.name,
                                isSelected: _selectedCategory == cat.slug,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat.slug;
                                    _applyFilters();
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ─── Difficulty & Type Filters ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: _difficulties.map((d) {
                            final isSelected = _selectedDifficulty == d;
                            final color = d == 'ALL'
                                ? AppTheme.primary
                                : _difficultyColor(d);
                            return FilterChip(
                              label: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedDifficulty = d;
                                  _applyFilters();
                                });
                              },
                              backgroundColor: AppTheme.surface,
                              selectedColor: color.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? color
                                    : AppTheme.textSecondary,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? color
                                    : AppTheme.surfaceLight,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: _types.map((t) {
                            final isSelected = _selectedType == t;
                            final color = t == 'ALL'
                                ? AppTheme.primary
                                : _typeColor(t);
                            return FilterChip(
                              label: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedType = t;
                                  _applyFilters();
                                });
                              },
                              backgroundColor: AppTheme.surface,
                              selectedColor: color.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? color
                                    : AppTheme.textSecondary,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? color
                                    : AppTheme.surfaceLight,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Questions List ───
                Expanded(
                  child: _filteredQuestions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                color: AppTheme.textSecondary,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No questions match your filters',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDifficulty = 'ALL';
                                    _selectedCategory = 'ALL';
                                    _selectedType = 'ALL';
                                    _applyFilters();
                                  });
                                },
                                child: const Text('Reset Filters'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppTheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount:
                                _getPaginatedQuestions().length +
                                (_currentPage <
                                        (_filteredQuestions.length / _pageSize)
                                                .ceil() -
                                            1
                                    ? 1
                                    : 0),
                            itemBuilder: (ctx, i) {
                              final paginatedQuestions =
                                  _getPaginatedQuestions();

                              if (i >= paginatedQuestions.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() => _currentPage++);
                                    },
                                    child: const Text('Load More'),
                                  ),
                                );
                              }

                              final q = paginatedQuestions[i];
                              final diffColor = _difficultyColor(q.difficulty);
                              final typeColor = _typeColor(q.type);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.surfaceLight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ─ Header Row ─
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: diffColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              q.difficulty,
                                              style: TextStyle(
                                                color: diffColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              q.type,
                                              style: TextStyle(
                                                color: typeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              q.category,
                                              style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${q.timeLimit}s',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // ─ Question Text ─
                                      Text(
                                        q.text,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.background.withValues(
                                            alpha: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              q.requiresWrittenAnswer
                                                  ? Icons.code_rounded
                                                  : Icons.fact_check_rounded,
                                              size: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              q.requiresWrittenAnswer
                                                  ? 'Written answer required'
                                                  : '${q.options.length} choices hidden until attempt',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // ─ Action Buttons ─
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: _startingQuiz
                                                  ? null
                                                  : () async {
                                                      await _startQuizFromQuestion(
                                                        q,
                                                      );
                                                    },
                                              icon: _startingQuiz
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.play_arrow_rounded,
                                                      size: 16,
                                                    ),
                                              label: Text(
                                                _startingQuiz
                                                    ? 'LOADING...'
                                                    : 'ATTEMPT',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (q.explanation.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text(
                                                        'Explanation',
                                                      ),
                                                      content:
                                                          SingleChildScrollView(
                                                            child: Text(
                                                              q.explanation,
                                                            ),
                                                          ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                ctx,
                                                              ),
                                                          child: const Text(
                                                            'Close',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'INFO',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
