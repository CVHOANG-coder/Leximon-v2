import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../discover/discover_screen.dart';
import '../home/home_screen.dart';
import '../learning_filter/learning_filter_screen.dart';
import '../messages/messages_screen.dart';
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

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
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
    const _MainTab(
      label: 'Thử thách',
      icon: Icons.shield_outlined,
      screen: MessagesScreen(),
    ),
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
      ref.invalidate(challengeDashboardProvider);
      ref.invalidate(progressDashboardProvider);
    }
    if (index == 3) {
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

  static const _animationDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : const Color(0xFFA8B4C5);
    final profileIconAsset = selected
        ? 'assets/images/tab_personal_active.png'
        : 'assets/images/tab_personal_inactive.png';

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
              AnimatedSlide(
                key: ValueKey('bottom-nav-slide-$label'),
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                offset: selected ? const Offset(0, -.06) : Offset.zero,
                child: AnimatedScale(
                  key: ValueKey('bottom-nav-scale-$label'),
                  duration: _animationDuration,
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.08 : 1,
                  child: AnimatedContainer(
                    key: ValueKey('bottom-nav-icon-$label'),
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    width: 38,
                    height: 34,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: selected && !profile
                          ? const LinearGradient(
                              colors: [Color(0xFF1658D3), Color(0xFF2481FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      boxShadow: selected && !profile
                          ? const [
                              BoxShadow(
                                color: Color(0x332F80ED),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: .72,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: profile
                          ? Image.asset(
                              profileIconAsset,
                              key: ValueKey(profileIconAsset),
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              icon,
                              key: ValueKey('$label-$selected'),
                              color: iconColor,
                              size: 21,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF2475E6)
                      : const Color(0xFFA8B4C5),
                  fontSize: 9,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(label),
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
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: 1 / 2,
            child: Image.asset(
              'assets/images/banner_header.png',
              key: const ValueKey('main-header-banner'),
              fit: BoxFit.fill,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ],
    );
  }
}
