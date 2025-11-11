import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../core/auth_gate.dart';

class AppRoot extends StatelessWidget {
  final bool firebaseReady;

  const AppRoot({required this.firebaseReady, super.key});

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(showRetry: true),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
