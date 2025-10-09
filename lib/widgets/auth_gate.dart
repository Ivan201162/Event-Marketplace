import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/up_user.dart';
import '../data/repositories/user_repository.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/modern_auth_screen.dart';

final firebaseUserProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

final currentUserProvider = StreamProvider<UpUser?>((ref) {
  final fbUserAsync = ref.watch(firebaseUserProvider);
  return fbUserAsync.when(
    data: (fbUser) {
      if (fbUser == null) {
        // not signed in
        return Stream<UpUser?>.value(null);
      }
      return UserRepository().watchUser(fbUser.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Ошибка авторизации: $e'))),
      data: (user) {
        if (user == null)
          return const ModernAuthScreen(); // <- всегда показываем вход
        return const MainNavigationScreen(); // BottomNavigation с Главная/Лента/Заявки/Чаты/Идеи
      },
    );
  }
}
