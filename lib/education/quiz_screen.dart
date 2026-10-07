import 'package:flutter/material.dart';

import '../data/education_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _questions = EducationData.quiz;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _finished = false;

  void _choose(int i) {
    if (_selected != null) return;
    setState(() {
      _selected = i;
      if (i == _questions[_index].answer) _score++;
    });
  }

  void _next() {
    setState(() {
      if (_index == _questions.length - 1) {
        _finished = true;
      } else {
        _index++;
        _selected = null;
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Readiness Quiz',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(child: _finished ? _result() : _question()),
    );
  }

  Widget _question() {
    final q = _questions[_index];
    final answered = _selected != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              _questions.length,
              (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: i < _questions.length - 1 ? 6 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: i <= _index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'QUESTION ${_index + 1} OF ${_questions.length}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(q.question, style: AppTheme.heading(size: 26)),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++) _option(q, i),
          if (answered) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                q.explanation,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _next,
              child: Text(
                _index == _questions.length - 1
                    ? 'See my result'
                    : 'Next question',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(QuizQuestion q, int i) {
    Color bg = AppColors.surface;
    Color border = AppColors.border;
    IconData? icon;

    if (_selected != null) {
      if (i == q.answer) {
        bg = AppColors.success.withValues(alpha: 0.10);
        border = AppColors.success;
        icon = Icons.check_circle;
      } else if (i == _selected) {
        bg = AppColors.criticalSoft;
        border = AppColors.critical;
        icon = Icons.cancel;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _choose(i),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  q.options[i],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: i == q.answer ? AppColors.success : AppColors.critical,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _result() {
    final total = _questions.length;
    final message = _score >= 4
        ? 'Your household is well prepared.'
        : _score == 3
        ? 'Almost there. Review the guides and try again.'
        : 'Keep practising. Read the guides, then retake the quiz.';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: Text('$_score/$total', style: AppTheme.heading(size: 44)),
          ),
          const SizedBox(height: 24),
          Text('Quiz complete', style: AppTheme.heading(size: 28)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _score),
            child: const Text('Back to Education Hub'),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _restart, child: const Text('Retake quiz')),
        ],
      ),
    );
  }
}
