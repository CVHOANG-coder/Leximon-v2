import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

enum DifficultWordsResultAction { continueTraining, exit }

enum _ResultLevel { bad, good, excellent }

class DifficultWordsResultScreen extends StatelessWidget {
  const DifficultWordsResultScreen({
    required this.healedWordCount,
    required this.trainedWordCount,
    required this.remainingWordCount,
    super.key,
  });

  final int healedWordCount;
  final int trainedWordCount;
  final int remainingWordCount;

  _ResultLevel get _level {
    final percent = trainedWordCount == 0
        ? 100
        : healedWordCount * 100 / trainedWordCount;
    if (percent < 25) return _ResultLevel.bad;
    if (percent < 40) return _ResultLevel.good;
    return _ResultLevel.excellent;
  }

  bool get _isComplete => remainingWordCount == 0;

  @override
  Widget build(BuildContext context) {
    final level = _level;
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          const Positioned.fill(child: _ResultBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: Text(
                          context.l10n.text('difficultResultEyebrow'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xC7FFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      _CloseButton(
                        onTap: () => Navigator.of(
                          context,
                        ).pop(DifficultWordsResultAction.exit),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 198,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 186,
                                  height: 186,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: .12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: .18,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  _isComplete
                                      ? 'assets/images/leximon-owl-wave.png'
                                      : 'assets/images/leximon-owl.png',
                                  height: 188,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _titleFor(context, level),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: 1.06,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _messageFor(context, level),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xD6FFFFFF),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .96),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33061C4B),
                                  blurRadius: 36,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ResultStat(
                                        icon: Icons.healing_rounded,
                                        value: '$healedWordCount',
                                        label: context.l10n.text(
                                          'difficultResultHealedUnit',
                                        ),
                                        color: AppColors.green,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 56,
                                      color: AppColors.divider,
                                    ),
                                    Expanded(
                                      child: _ResultStat(
                                        icon: Icons.fact_check_rounded,
                                        value: '$trainedWordCount',
                                        label: context.l10n.text(
                                          'difficultResultTrainedUnit',
                                        ),
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_isComplete) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E8),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.replay_circle_filled_rounded,
                                          color: AppColors.orange,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            context.l10n.text(
                                              'difficultResultRemaining',
                                              values: {
                                                'count': remainingWordCount,
                                              },
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(
                        _isComplete
                            ? DifficultWordsResultAction.exit
                            : DifficultWordsResultAction.continueTraining,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        _isComplete
                            ? context.l10n.text(
                                'difficultResultCompleteAction',
                              )
                            : level == _ResultLevel.bad
                            ? context.l10n.text('difficultResultRetryAction')
                            : context.l10n.text(
                                'difficultResultContinueAction',
                              ),
                      ),
                    ),
                  ),
                  if (!_isComplete) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(DifficultWordsResultAction.exit),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        context.l10n.text('difficultResultExitToList'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(BuildContext context, _ResultLevel level) {
    if (_isComplete) {
      return context.l10n.text('difficultResultAllFixedTitle');
    }
    return switch (level) {
      _ResultLevel.bad => context.l10n.text('difficultResultBadTitle'),
      _ResultLevel.good => context.l10n.text('difficultResultGoodTitle'),
      _ResultLevel.excellent => context.l10n.text(
        'difficultResultExcellentTitle',
      ),
    };
  }

  String _messageFor(BuildContext context, _ResultLevel level) {
    if (_isComplete) {
      return context.l10n.text('difficultResultCompleteBody');
    }
    return switch (level) {
      _ResultLevel.bad => context.l10n.text('difficultResultRetryBody'),
      _ResultLevel.good => context.l10n.text('difficultResultContinueBody'),
      _ResultLevel.excellent => context.l10n.text(
        'difficultResultExcellentBody',
      ),
    };
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.close_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ResultBackdrop extends StatelessWidget {
  const _ResultBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF071A3D),
            Color(0xFF0F58D8),
            Color(0xFF28A3EF),
            Color(0xFF58CCFF),
          ],
          stops: [0, .34, .68, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
