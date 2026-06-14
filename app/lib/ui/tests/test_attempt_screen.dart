import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question.dart';
import '../../providers/game_state_provider.dart';
import '../../services/question_service.dart';
import '../../core/theme.dart';

class TestAttemptScreen extends StatefulWidget {
  final Question? question;
  final List<Question>? questions;

  TestAttemptScreen({super.key, this.question, this.questions})
      : assert(question != null || (questions != null && questions.isNotEmpty));

  @override
  State<TestAttemptScreen> createState() => _TestAttemptScreenState();
}

class _TestAttemptScreenState extends State<TestAttemptScreen>
    with SingleTickerProviderStateMixin {
  late final List<Question> _questions;
  int _currentIndex = 0;
  String? _selectedOptionId;
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  bool? _isCorrect;
  int? _correctOptionId;
  String _correctAnswer = '';
  String _explanation = '';
  int _coinsEarned = 0;
  int _expEarned = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  late AnimationController _resultAnim;
  late Animation<double> _resultScale;

  Question get _currentQuestion => _questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _questions.length - 1;
  bool get _isSingleQuestion => _questions.length == 1;
  bool get _isWrittenAnswer => _currentQuestion.requiresWrittenAnswer;
  String get _actionLabel {
    if (!_isSubmitted) return 'SUBMIT ANSWER';
    if (_isSingleQuestion) return 'BACK TO PRACTICE';
    return _isLastQuestion ? 'FINISH QUIZ' : 'NEXT QUESTION';
  }
  String get _timerLabel {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _questions = widget.questions ?? [widget.question!];
    _resultAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _resultScale =
        CurvedAnimation(parent: _resultAnim, curve: Curves.elasticOut);
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    _resultAnim.dispose();
    super.dispose();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _isWrittenAnswer ? 300 : _currentQuestion.timeLimit;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isSubmitted) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        _submitAnswer(force: true);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  bool _answersMatch(String userAnswer, String correctAnswer) {
    String normalize(String value) =>
        value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return normalize(userAnswer) == normalize(correctAnswer);
  }

  Future<void> _submitAnswer({bool force = false}) async {
    final answerText = _answerController.text.trim();
    final parts = _PromptParts.fromQuestion(_currentQuestion);
    final hasAnswer =
        _isWrittenAnswer ? answerText.isNotEmpty : _selectedOptionId != null;
    if ((!hasAnswer && !force) || _isSubmitting || _isSubmitted) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final result = await QuestionService.submitAnswer(
      questionId: _currentQuestion.id,
      selectedOptionId: _selectedOptionId,
      codeAnswer: _isWrittenAnswer ? answerText : null,
    );

    if (!mounted) return;

    if (result != null) {
      final backendCorrectAnswer = (result['correct_answer'] ?? '').toString();
      final expectedAnswer = backendCorrectAnswer.isNotEmpty
          ? backendCorrectAnswer
          : parts.expectedAnswer;
      final locallyCorrect = expectedAnswer.isNotEmpty
          ? _answersMatch(answerText, expectedAnswer)
          : result['is_correct'] == true;
      final userData = result['user'] as Map<String, dynamic>?;
      if (userData != null) {
        Provider.of<GameStateProvider>(context, listen: false)
            .syncFromServer(userData);
      }
      setState(() {
        _isCorrect =
            _isWrittenAnswer ? locallyCorrect : result['is_correct'] == true;
        _correctOptionId = result['correct_option_id'];
        _coinsEarned = result['coins_earned'] ?? 0;
        _expEarned = result['exp_earned'] ?? 0;
        _correctAnswer = expectedAnswer;
        _explanation = (result['explanation'] ?? parts.explanation).toString();
        _isSubmitted = true;
        _isSubmitting = false;
      });
      _resultAnim.forward();
    } else {
      final gameState = Provider.of<GameStateProvider>(context, listen: false);
      if (_isWrittenAnswer) {
        final isCorrect = parts.expectedAnswer.isNotEmpty
            ? _answersMatch(answerText, parts.expectedAnswer)
            : answerText.isNotEmpty;
        if (isCorrect) {
          gameState.addCoins(50);
          gameState.addExp(100);
        } else {
          gameState.loseLife();
        }
        setState(() {
          _isCorrect = isCorrect;
          _coinsEarned = isCorrect ? 50 : 0;
          _expEarned = isCorrect ? 100 : 0;
          _correctAnswer = parts.expectedAnswer;
          _explanation = parts.explanation;
        });
        _correctOptionId = null;
      } else {
        final selected = _selectedOptionId == null
            ? null
            : _currentQuestion.options.firstWhere(
                (o) => o.id == _selectedOptionId,
                orElse: () => _currentQuestion.options.first,
              );
        if (selected?.isCorrect == true) {
          gameState.addCoins(50);
          gameState.addExp(100);
          setState(() {
            _isCorrect = true;
            _coinsEarned = 50;
            _expEarned = 100;
          });
        } else {
          gameState.loseLife();
          setState(() => _isCorrect = false);
        }
        final correct = _currentQuestion.options
            .firstWhere((o) => o.isCorrect,
                orElse: () => selected ?? _currentQuestion.options.first);
        _correctOptionId = int.tryParse(correct.id);
      }
      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
      _resultAnim.forward();
    }
  }

  Future<void> _goToNextQuestion() async {
    if (_isLastQuestion) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentIndex++;
      _selectedOptionId = null;
      _answerController.clear();
      _isSubmitted = false;
      _isCorrect = null;
      _correctOptionId = null;
      _correctAnswer = '';
      _explanation = '';
      _coinsEarned = 0;
      _expEarned = 0;
    });
    _resultAnim.reset();
    _startQuestionTimer();
  }

  bool _isOptionCorrect(QuestionOption o) {
    if (_correctOptionId != null) return o.id == _correctOptionId.toString();
    return o.isCorrect;
  }

  Color _diffColor(String d) {
    switch (d) {
      case 'EASY':
        return AppTheme.secondary;
      case 'HARD':
        return AppTheme.error;
      default:
        return AppTheme.accent;
    }
  }

  String? _submittedUserAnswer(Question q) {
    if (_isWrittenAnswer) return _answerController.text.trim();
    for (final option in q.options) {
      if (option.id == _selectedOptionId) return option.text;
    }
    return null;
  }

  String? _submittedCorrectAnswer(Question q) {
    if (_isWrittenAnswer) return _correctAnswer;
    for (final option in q.options) {
      if (_isOptionCorrect(option)) return option.text;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final dc = _diffColor(q.difficulty);
    final promptParts = _PromptParts.fromQuestion(q);

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSubmitted)
                ScaleTransition(
                  scale: _resultScale,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: (_isCorrect == true
                              ? AppTheme.secondary
                              : AppTheme.error)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (_isCorrect == true
                                ? AppTheme.secondary
                                : AppTheme.error)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isCorrect == true
                                  ? Icons.emoji_events_rounded
                                  : Icons.sentiment_dissatisfied_rounded,
                              color: _isCorrect == true
                                  ? AppTheme.secondary
                                  : AppTheme.error,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isCorrect == true
                                  ? '+$_coinsEarned Coins  +$_expEarned XP 🎉'
                                  : 'Incorrect! -1 Life ❤️',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isCorrect == true
                                    ? AppTheme.secondary
                                    : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                        if (_explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(color: AppTheme.surfaceLight),
                          const SizedBox(height: 4),
                          Text(
                            '💡 $_explanation',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.45,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_isSubmitted ? _goToNextQuestion : _submitAnswer),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor:
                        _isSubmitted ? AppTheme.secondary : AppTheme.primary,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _actionLabel,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 15, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text(_timerLabel,
                        style: const TextStyle(
                            color: AppTheme.accent, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          _Badge(label: q.difficulty, color: dc),
                          _Badge(label: q.type, color: AppTheme.primary),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SelectableText(
                        promptParts.questionText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isWrittenAnswer) ...[
                  TextField(
                    controller: _answerController,
                    enabled: !_isSubmitted,
                    minLines: 3,
                    maxLines: 6,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter the output / answer',
                      hintStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppTheme.surfaceLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppTheme.surfaceLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  ...q.options.map((option) {
                  final isSelected = _selectedOptionId == option.id;
                  final isCorrect =
                      _isSubmitted && _isOptionCorrect(option);
                  final isWrong = _isSubmitted &&
                      isSelected &&
                      !_isOptionCorrect(option);

                  late Color borderColor;
                  late Color bgColor;
                  late IconData iconData;
                  late Color iconColor;

                  if (isCorrect) {
                    borderColor = AppTheme.secondary;
                    bgColor = AppTheme.secondary.withValues(alpha: 0.12);
                    iconData = Icons.check_circle_rounded;
                    iconColor = AppTheme.secondary;
                  } else if (isWrong) {
                    borderColor = AppTheme.error;
                    bgColor = AppTheme.error.withValues(alpha: 0.12);
                    iconData = Icons.cancel_rounded;
                    iconColor = AppTheme.error;
                  } else if (isSelected) {
                    borderColor = AppTheme.primary;
                    bgColor = AppTheme.primary.withValues(alpha: 0.08);
                    iconData = Icons.radio_button_checked;
                    iconColor = AppTheme.primary;
                  } else {
                    borderColor = AppTheme.surfaceLight;
                    bgColor = AppTheme.surface;
                    iconData = Icons.radio_button_unchecked;
                    iconColor = AppTheme.textSecondary;
                  }

                  return GestureDetector(
                    onTap: _isSubmitted
                        ? null
                        : () => setState(
                            () => _selectedOptionId = option.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(iconData,
                                color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option.text,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_isSubmitted)
                  _ResultDetailsCard(
                    userAnswer: _submittedUserAnswer(q),
                    correctAnswer: _submittedCorrectAnswer(q),
                    explanation: _explanation,
                  ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small reusable badge ──────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      );
}

class _ResultDetailsCard extends StatelessWidget {
  final String? userAnswer;
  final String? correctAnswer;
  final String explanation;

  const _ResultDetailsCard({
    required this.userAnswer,
    required this.correctAnswer,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Result',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((userAnswer ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailLine(label: 'Your answer', value: userAnswer!),
            ],
            if ((correctAnswer ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailLine(label: 'Correct answer', value: correctAnswer!),
            ],
            if (explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Detailed explanation',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                explanation.trim(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      );
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      );
}

class _PromptParts {
  final String questionText;
  final String expectedAnswer;
  final String explanation;

  const _PromptParts({
    required this.questionText,
    required this.expectedAnswer,
    required this.explanation,
  });

  factory _PromptParts.fromQuestion(Question question) {
    final rawText = question.text.trim();
    final outputMatch = RegExp(
      r'^\s*(?:sample\s+|expected\s+)?output\s*:.*$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(rawText);
    final explanationMatch = RegExp(
      r'^\s*explanation\s*:?-?\s*.*$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(rawText);
    final splitIndex = outputMatch?.start ?? explanationMatch?.start;
    final visibleQuestion = splitIndex == null
        ? rawText
        : rawText.substring(0, splitIndex).trim();
    final embeddedExplanation = _extractExplanation(rawText);

    return _PromptParts(
      questionText: visibleQuestion.isEmpty ? rawText : visibleQuestion,
      expectedAnswer: _extractExpectedAnswer(rawText),
      explanation: embeddedExplanation.isNotEmpty
          ? embeddedExplanation
          : question.explanation.trim(),
    );
  }

  static String _extractExpectedAnswer(String text) {
    final match = RegExp(
      r'^\s*(?:sample\s+|expected\s+)?output\s*:\s*(.*)$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return '';

    final sameLine = (match.group(1) ?? '').trim();
    if (sameLine.isNotEmpty && !sameLine.startsWith('(')) return sameLine;

    final answerLines = <String>[];
    final tail = text.substring(match.end).split(RegExp(r'\r?\n'));
    final stopPattern = RegExp(
      r'^\s*(?:explanation|sample\s+input|input|expected\s+output|output)\s*:?',
      caseSensitive: false,
    );
    for (final line in tail) {
      final trimmed = line.trim();
      if (trimmed.isEmpty && answerLines.isEmpty) continue;
      if (stopPattern.hasMatch(trimmed)) break;
      if (trimmed.isNotEmpty) answerLines.add(trimmed);
    }
    return answerLines.join('\n').trim();
  }

  static String _extractExplanation(String text) {
    final match = RegExp(
      r'^\s*explanation\s*:?-?\s*(.*)$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return '';

    final lines = <String>[];
    final sameLine = (match.group(1) ?? '').trim();
    if (sameLine.isNotEmpty) lines.add(sameLine);
    lines.addAll(text.substring(match.end).split(RegExp(r'\r?\n')));
    return lines.join('\n').trim();
  }
}
