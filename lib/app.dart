import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/main/main_screen.dart';
import 'shared/providers/app_providers.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => const MainScreen())],
);

class LeximonApp extends ConsumerWidget {
  const LeximonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localDataInitializationProvider);
    return MaterialApp.router(
      title: 'Leximon',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
