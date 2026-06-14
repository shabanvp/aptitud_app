import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/question.dart';
import '../../providers/game_state_provider.dart';
import '../../services/question_service.dart';
import 'test_attempt_screen.dart';

class CategoryPracticeScreen extends StatefulWidget {
  final Category category;
  const CategoryPracticeScreen({super.key, required this.category});

  @override
  State<CategoryPracticeScreen> createState() => _CategoryPracticeScreenState();
}

class _CategoryPracticeScreenState extends State<CategoryPracticeScreen> {
  List<Question> _questions = [];
  bool _loading = true;
  bool _startingQuiz = false;
  String _selectedDifficulty = 'ALL';

  final _difficulties = ['ALL', 'EASY', 'MEDIUM', 'HARD'];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    final qs = await QuestionService.fetchQuestions(
      categorySlug: widget.category.slug,
      difficulty: _selectedDifficulty == 'ALL' ? null : _selectedDifficulty,
      limit: 20,
    );
    if (mounted) {
      setState(() {
        _questions = qs;
        _loading = false;
      });
    }
  }

  Future<void> _startQuizSession([Question? startQuestion]) async {
    if (_startingQuiz) return;
    setState(() => _startingQuiz = true);

    final questions = await QuestionService.fetchQuestions(
      categorySlug: widget.category.slug,
      difficulty: _selectedDifficulty == 'ALL' ? null : _selectedDifficulty,
      limit: 10,
    );

    if (!mounted) return;
    setState(() => _startingQuiz = false);

    final uniqueQuestions = <String, Question>{};
    for (final q in questions) {
      uniqueQuestions[q.id] = q;
    }

    final quizQuestions = uniqueQuestions.values.toList();
    if (startQuestion != null) {
      quizQuestions.removeWhere((q) => q.id == startQuestion.id);
      quizQuestions.insert(0, startQuestion);
    }
    if (quizQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start quiz. Please try again.'),
        ),
      );
      return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.category.name, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${widget.category.questionCount} Questions',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Difficulty Filter ────────────────────────────────
          Container(
            height: 44,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _difficulties.map((d) {
                final isSelected = _selectedDifficulty == d;
                final color = d == 'ALL'
                    ? AppTheme.primary
                    : _difficultyColor(d);
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDifficulty = d);
                    _loadQuestions();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.surfaceLight,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      d,
                      style: TextStyle(
                        color: isSelected ? color : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Question List ────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.quiz_rounded,
                          color: AppTheme.textSecondary,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No questions available\nfor this filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedDifficulty = 'ALL');
                            _loadQuestions();
                          },
                          child: const Text('Show All'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadQuestions,
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _questions.length,
                      itemBuilder: (ctx, i) => _QuestionCard(
                        question: _questions[i],
                        index: i,
                        onAttempt: () async {
                          await _startQuizSession(_questions[i]);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final VoidCallback onAttempt;
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.onAttempt,
  });

  Color get _diffColor {
    switch (question.difficulty) {
      case 'EASY':
        return AppTheme.secondary;
      case 'HARD':
        return AppTheme.error;
      default:
        return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _diffColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    question.difficulty,
                    style: TextStyle(
                      color: _diffColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    question.type,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  '${question.timeLimit}s',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Question text
            Text(
              question.text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    question.requiresWrittenAnswer
                        ? Icons.code_rounded
                        : Icons.fact_check_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    question.requiresWrittenAnswer
                        ? 'Written answer required'
                        : '${question.options.length} choices hidden until attempt',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAttempt,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text(
                  'ATTEMPT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
