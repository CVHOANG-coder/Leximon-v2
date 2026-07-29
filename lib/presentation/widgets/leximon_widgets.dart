import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/topic.dart';

// Legacy fallback for screens that do not yet receive the local progress map.
// Home passes the database-backed value directly to TopicCard.
const topicProgressByOrder = <int, double>{
  1: .64,
  2: 0,
  3: .12,
  4: 0,
  5: .31,
  6: .08,
  7: .22,
  8: .52,
  9: .38,
  10: .24,
  11: .18,
  12: .45,
};

double topicProgress(Topic topic) => topicProgressByOrder[topic.order] ?? 0;

const topicIconByOrder = <int, String>{
  1: 'travel.svg',
  2: 'shopping.svg',
  3: 'family_and_friends.svg',
  4: 'school_and_university.svg',
  5: 'work_and_employment.svg',
  6: 'in_a_job_interview.svg',
  7: 'business_and_finance.svg',
  8: 'communication.svg',
  9: 'friends_TV_series.svg',
  10: 'character.svg',
  11: 'feelings_and_emotions.svg',
  12: 'eating_out.svg',
  13: 'food_and_drink.svg',
  14: 'human_body.svg',
  15: 'health_and_medicine.svg',
  16: 'at_home.svg',
  17: 'in_the_city.svg',
  18: 'clothes_and_accessories.svg',
  19: 'cinema_and_theater.svg',
  20: 'activities_and_interests.svg',
  21: 'technology.svg',
  22: 'design_and_innovation.svg',
  23: 'lifestyles.svg',
  24: 'the_media.svg',
  25: 'space_and_science.svg',
  26: 'the_environment.svg',
  27: 'idioms.svg',
  28: 'linking_words.svg',
  29: 'everything_about_time.svg',
  30: 'top_100_adjectives.svg',
  31: 'top_100_verb.svg',
  32: 'top_100_adverbs.svg',
  33: 'weather_and_Climate.svg',
  34: 'animals.svg',
  35: 'celebrations.svg',
  36: 'physical_geography.svg',
  37: 'notices_and_signs.svg',
  38: 'forms_of_transport.svg',
  39: 'driving.svg',
  40: 'sports.svg',
  41: 'music.svg',
  42: 'law_and_order.svg',
  43: 'politics_and_government.svg',
  44: 'plants.svg',
  45: 'journey_into_the_past.svg',
  46: 'notional_concepts.svg',
  71: 'slang.svg',
};

String topicIconAsset(Topic topic) =>
    'assets/svgs/${topicIconByOrder[topic.order] ?? 'travel.svg'}';

String topicEmoji(Topic topic) {
  const emojis = [
    '✈️',
    '🛍️',
    '👨‍👩‍👧',
    '🎓',
    '💼',
    '🗣️',
    '💰',
    '💬',
    '📺',
    '🎭',
    '💛',
    '🍽️',
    '🍜',
    '🩺',
    '❤️',
    '🏠',
    '🏙️',
    '👕',
    '🎬',
    '🎨',
    '💻',
    '💡',
    '🌿',
    '📰',
    '🚀',
    '🌍',
    '🧩',
    '🔗',
    '⏰',
    '📝',
    '⚡',
    '✨',
    '🌦️',
    '🐾',
    '🎉',
    '🗺️',
    '🚦',
    '🚆',
    '🚗',
    '⚽',
    '🎵',
    '⚖️',
    '🏛️',
    '🌱',
    '⌛',
    '🧠',
    '😎',
  ];
  return emojis[(topic.order - 1).clamp(0, emojis.length - 1)];
}

List<Color> topicGradient(Topic topic) {
  const gradients = <List<Color>>[
    [Color(0xFFFF9C56), Color(0xFFFF4F70)],
    [Color(0xFFFFCF4B), Color(0xFFFF8B22)],
    [Color(0xFFFF87AF), Color(0xFFC756FF)],
    [Color(0xFF6A9DFF), Color(0xFF5844E8)],
    [Color(0xFF27C7C6), Color(0xFF126BD9)],
    [Color(0xFF9A78FF), Color(0xFF5B3FE7)],
    [Color(0xFFFFD166), Color(0xFFF28F3B)],
    [Color(0xFF56D8FF), Color(0xFF1982C4)],
    [Color(0xFFB279A2), Color(0xFF6C4AB6)],
    [Color(0xFFF4978E), Color(0xFFF26A8D)],
    [Color(0xFFFFAFCC), Color(0xFFCDB4DB)],
    [Color(0xFFFFBC45), Color(0xFFEC5A4B)],
    [Color(0xFFFF9F68), Color(0xFFD95D39)],
    [Color(0xFF7BDFF2), Color(0xFF1D8A99)],
    [Color(0xFF68D391), Color(0xFF1A9A70)],
    [Color(0xFFFFD6A5), Color(0xFFF4A261)],
    [Color(0xFF7CC4FF), Color(0xFF2563EB)],
    [Color(0xFFE0A9C9), Color(0xFFA64D79)],
    [Color(0xFFFF7B72), Color(0xFFD1495B)],
    [Color(0xFFF9F871), Color(0xFFA8C256)],
    [Color(0xFF65D6CE), Color(0xFF1C9A9A)],
    [Color(0xFFCDB4DB), Color(0xFF7A5CFA)],
    [Color(0xFFA8D5BA), Color(0xFF5E9C76)],
    [Color(0xFFBDE0FE), Color(0xFF5B8DEF)],
    [Color(0xFF8E9BFF), Color(0xFF4B4EAF)],
    [Color(0xFF95D5B2), Color(0xFF3A9D6C)],
    [Color(0xFFFFB4A2), Color(0xFFE56B6F)],
    [Color(0xFFA9DEF9), Color(0xFF5DADE2)],
    [Color(0xFFD0BFFF), Color(0xFF8A6FD1)],
    [Color(0xFFFFE08A), Color(0xFFD9A441)],
    [Color(0xFF91E6B3), Color(0xFF3BB273)],
    [Color(0xFFF7B2D8), Color(0xFFC05DA9)],
    [Color(0xFFA1C6EA), Color(0xFF4A90E2)],
    [Color(0xFFB5E48C), Color(0xFF52B788)],
    [Color(0xFFFFD166), Color(0xFFEF8354)],
    [Color(0xFF8FD3B3), Color(0xFF5E60CE)],
    [Color(0xFFF4A261), Color(0xFFE76F51)],
    [Color(0xFF7BDFF2), Color(0xFF00A6A6)],
    [Color(0xFFFF9F9F), Color(0xFFD62828)],
    [Color(0xFF90DBF4), Color(0xFF277DA1)],
    [Color(0xFFF5A6E6), Color(0xFF9B5DE5)],
    [Color(0xFFFFE1A8), Color(0xFFFFC857)],
    [Color(0xFFA9BCFF), Color(0xFF3D5A80)],
    [Color(0xFFB7E4C7), Color(0xFF52B788)],
    [Color(0xFFC9ADA7), Color(0xFF6D597A)],
    [Color(0xFFB8B8FF), Color(0xFF6A67CE)],
    [Color(0xFFD4A5A5), Color(0xFF9D4EDD)],
  ];
  final index = (topic.order - 1).clamp(0, gradients.length - 1);
  return gradients[index];
}

class LeximonSurface extends StatelessWidget {
  const LeximonSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B144099),
            blurRadius: 55,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: radius,
              border: Border.all(color: const Color(0x2AFFFFFF)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.kicker,
    required this.title,
    this.action,
    this.onAction,
    super.key,
  });

  final String kicker;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF7990B0),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction ?? () {}, child: Text(action!)),
      ],
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({required this.value, this.dark = false, super.key});

  final double value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: dark
            ? Colors.white.withValues(alpha: .16)
            : const Color(0xFFE7EEF8),
        valueColor: AlwaysStoppedAnimation(
          dark ? AppColors.cyan : AppColors.primary,
        ),
      ),
    );
  }
}

class OwlAvatar extends StatelessWidget {
  const OwlAvatar({this.size = 54, this.radius = 17, super.key});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D75FF), Color(0xFF064EE0)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x361258FF),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: Image.asset('assets/images/leximon-owl.png', fit: BoxFit.cover),
      ),
    );
  }
}

class TopicCard extends StatelessWidget {
  const TopicCard({required this.topic, this.progress, this.onTap, super.key});

  final Topic topic;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progressValue = (progress ?? topicProgress(topic))
        .clamp(0, 1)
        .toDouble();
    final learned = (topic.wordCount * progressValue).round();
    final colors = topicGradient(topic);
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFDCE6F2)),
    );
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x3327477F),
      shape: cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: cardShape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: LinearGradient(colors: colors),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: TopicArtwork(topic: topic)),
                        if (learned > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x66051C42),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '${(progressValue * 100).round()}%',
                                style: const TextStyle(
                                  inherit: false,
                                  color: Colors.white,
                                  fontSize: 7,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  topic.translated,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$learned / ${topic.wordCount} từ',
                            style: const TextStyle(
                              fontSize: 8,
                              height: 1,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _TopicProgressLine(value: progressValue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: progressValue > 0
                        ? AppColors.green
                        : const Color(0xFFD9E0EB),
                    boxShadow: progressValue > 0
                        ? const [
                            BoxShadow(
                              color: Color(0x1F23C888),
                              blurRadius: 0,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicProgressLine extends StatelessWidget {
  const _TopicProgressLine({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFEDF1F6)),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
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

class TopicArtwork extends StatelessWidget {
  const TopicArtwork({required this.topic, this.padding = 10, super.key});

  final Topic topic;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SvgPicture.asset(
        topicIconAsset(topic),
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            Text(topicEmoji(topic), style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
