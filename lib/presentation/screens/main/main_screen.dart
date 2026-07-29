import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../discover/discover_screen.dart';
import '../home/home_screen.dart';
import '../learning_filter/learning_filter_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final tabs = _buildTabs(ref);
        final selectedIndex = _selectedIndex >= tabs.length
            ? tabs.length - 1
            : _selectedIndex;
        ref.watch(selectedTopicOrdersHydrationProvider);
        if (ref.watch(topicSetupOpenProvider)) {
          return LearningFilterScreen(
            startAtTopics: ref.watch(topicSetupStartAtTopicsProvider),
            onExit: () => _closeTopicSetup(ref),
            onFinished: () => _closeTopicSetup(ref),
          );
        }

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _AppBackdrop(),
              Positioned.fill(
                child: IndexedStack(
                  index: selectedIndex,
                  children: [for (final tab in tabs) tab.screen],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            selectedIndex: selectedIndex,
            tabs: tabs,
            onDestinationSelected: (index) => _selectTab(ref, index),
          ),
        );
      },
    );
  }

  List<_MainTab> _buildTabs(WidgetRef ref) => [
    const _MainTab(
      label: 'Học tập',
      icon: Icons.menu_book_outlined,
      screen: HomeScreen(),
    ),
    const _MainTab(
      label: 'Tiến độ',
      icon: Icons.bar_chart_outlined,
      screen: DiscoverScreen(),
    ),
    // Temporarily hidden until the challenge flow is ready.
    // const _MainTab(
    //   label: 'Thử thách',
    //   icon: Icons.shield_outlined,
    //   screen: MessagesScreen(),
    // ),
    _MainTab(
      label: 'Cá nhân',
      screen: ProfileScreen(onViewProgress: () => _selectTab(ref, 1)),
      profile: true,
    ),
  ];

  void _selectTab(WidgetRef ref, int index) {
    if (index == 1) {
      // IndexedStack keeps DiscoverScreen alive, so explicitly reload local
      // progress whenever the tab is opened again.
      ref.invalidate(progressDashboardProvider);
      ref.invalidate(topicProgressProvider);
      ref.invalidate(vocabularyCollectionProvider);
    }
    if (index == 2) {
      ref.invalidate(profileStatisticsProvider);
      ref.invalidate(topicProgressProvider);
    }
    setState(() => _selectedIndex = index);
  }

  void _closeTopicSetup(WidgetRef ref) {
    ref.read(topicSetupStartAtTopicsProvider.notifier).state = true;
    ref.read(topicSetupOpenProvider.notifier).state = false;
  }
}

class _MainTab {
  const _MainTab({
    required this.label,
    required this.screen,
    this.icon,
    this.profile = false,
  });

  final String label;
  final IconData? icon;
  final Widget screen;
  final bool profile;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.tabs,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<_MainTab> tabs;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xF0FFFFFF),
              border: Border(top: BorderSide(color: Color(0x14071A3D))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x12163873),
                  blurRadius: 30,
                  offset: Offset(0, -12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Row(
                children: [
                  for (var index = 0; index < tabs.length; index++)
                    Expanded(
                      child: _BottomNavItem(
                        icon: tabs[index].icon,
                        label: tabs[index].label,
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
                        profile: tabs[index].profile,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.profile = false,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool profile;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : const Color(0xFF9AA7B9);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 34,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: profile ? const Color(0xFFF0F4FB) : null,
                  border: profile
                      ? Border.all(color: const Color(0xFFE4EAF5))
                      : null,
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF0D3A91), Color(0xFF155CFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x3D1258FF),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: profile
                    ? Transform.scale(
                        scale: 1.13,
                        child: Image.asset(
                          'assets/images/leximon-owl.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : const Color(0xFF9AA7B9),
                  fontSize: 9,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBackdrop extends StatelessWidget {
  const _AppBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 350,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(46)),
            gradient: LinearGradient(
              colors: [Color(0xFF061B43), Color(0xFF0B347F), Color(0xFF155CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: 70,
          left: -90,
          child: _GlowOrb(
            color: AppColors.cyan.withValues(alpha: .27),
            size: 210,
          ),
        ),
        Positioned(
          top: 178,
          right: -68,
          child: _GlowOrb(
            color: AppColors.cyan.withValues(alpha: .18),
            size: 155,
          ),
        ),
        Positioned(top: 104, right: 70, child: _Spark()),
        Positioned(
          top: 228,
          left: 55,
          child: Transform.scale(scale: .7, child: const _Spark()),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .55),
        boxShadow: const [
          BoxShadow(color: Colors.white, blurRadius: 12, spreadRadius: 2),
        ],
      ),
    );
  }
}
