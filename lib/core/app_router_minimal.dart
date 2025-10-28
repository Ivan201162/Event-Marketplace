import 'package:event_marketplace_app/screens/about_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Минимальный роутер для тестирования
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/about',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
