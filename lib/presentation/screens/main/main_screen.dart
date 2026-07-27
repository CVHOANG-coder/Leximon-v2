import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../discover/discover_screen.dart';
import '../home/home_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    HomeScreen(),
    DiscoverScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AppBackdrop(),
          IndexedStack(index: _selectedIndex, children: _screens),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Học tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Tiến độ',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Luyện tập',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
