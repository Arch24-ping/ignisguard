import 'package:flutter/material.dart';

import '../data/education_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import 'guide_screen.dart';
import 'quiz_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final _libraryKey = GlobalKey();
  String _query = '';
  int? _score; // null until the quiz has been taken

  List<Guide> get _filtered => EducationData.library
      .where(
        (g) =>
            '${g.title} ${g.summary} ${g.tag}'.toLowerCase().contains(_query),
      )
      .toList();

  void _open(Guide g) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GuideScreen(guide: g)));
  }

  Future<void> _startQuiz() async {
    final result = await Navigator.of(context)
        .push<int>(MaterialPageRoute(builder: (_) => const QuizScreen()));
    if (result != null && mounted) setState(() => _score = result);
  }

  void _scrollToLibrary() {
    final ctx = _libraryKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final results = _filtered;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Education'),
            const SizedBox(height: 18),
            Text('Safety Education Hub', style: AppTheme.heading(size: 30)),
            const SizedBox(height: 8),
            const Text(
              'Practical home protocols, extinguisher drills, and clear '
              'telemetry guides to keep your family protected.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _searchField(),
            const SizedBox(height: 18),
            if (!searching) ...[
              _readinessCard(),
              const SizedBox(height: 22),
              _label(
                'PRIORITY HOUSEHOLD GUIDE',
                right: 'View All Protocols',
                onRight: _scrollToLibrary,
              ),
              const SizedBox(height: 10),
              _priorityCard(),
              const SizedBox(height: 22),
              _label('STEP-BY-STEP TRAINING'),
              const SizedBox(height: 6),
              Text('The P.A.S.S. Method', style: AppTheme.heading(size: 24)),
              const SizedBox(height: 4),
              const Text(
                'The standardized protocol for operating household fire '
                'extinguishers safely.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _passGrid(),
              const SizedBox(height: 22),
            ],
            Container(
              key: _libraryKey,
              child: _label(
                'CORE LEARNING LIBRARY',
                right: '${results.length} Modules',
              ),
            ),
            const SizedBox(height: 10),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No guides match your search',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              for (final g in results) _libraryTile(g),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search guides, extinguisher tips, drills...',
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _label(String left, {String? right, VoidCallback? onRight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          left,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.textSecondary,
          ),
        ),
        if (right != null)
          GestureDetector(
            onTap: onRight,
            child: Text(
              right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: onRight != null ? FontWeight.w600 : FontWeight.w500,
                color: onRight != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _readinessCard() {
    final score = _score ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'FAMILY PREPAREDNESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _score == null
                      ? 'Not taken yet'
                      : 'Score: $score/5 ${score >= 4 ? 'Ready' : ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Test Your Readiness Quiz', style: AppTheme.heading(size: 22)),
          const SizedBox(height: 4),
          const Text(
            '5 quick, bite-sized questions to measure your household escape '
            'preparedness.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < score ? AppColors.primary : AppColors.border,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i < score ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(
                  _score == null ? 'Start 2-min Quiz' : 'Retake',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityCard() {
    final g = EducationData.kitchenGuide;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(g),
      child: Container(
        height: 170,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8A5B3C), Color(0xFF2B211B)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.critical,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Essential',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    g.meta,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              'KITCHEN EMERGENCIES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passCard(String letter, String title, String body) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: AppTheme.heading(size: 16)),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _passCard(
                'P',
                'Pull the Pin',
                'Break the tamper plastic seal by pulling the retaining '
                    'ring straight outward.',
              ),
              const SizedBox(width: 10),
              _passCard(
                'A',
                'Aim at Base',
                'Target the burning fuel bed below, never directly at '
                    'leaping open flames.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _passCard(
                'S',
                'Squeeze Lever',
                'Depress the handle steadily with a firm grip to release '
                    'the suppression agent.',
              ),
              const SizedBox(width: 10),
              _passCard(
                'S',
                'Sweep Horizontally',
                'Move the nozzle side to side across the base from 6 to '
                    '8 feet back until extinguished.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _libraryTile(Guide g) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(g),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(g.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            g.tag.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            g.meta,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(g.title, style: AppTheme.heading(size: 17)),
                    const SizedBox(height: 2),
                    Text(
                      g.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
