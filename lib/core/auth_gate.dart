import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран-ворота для проверки авторизации
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (!mounted) return;

      if (user == null) {
        debugLog("AUTH_SCREEN_SHOWN");
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          debugLog("AUTH_SCREEN_SHOWN");
          if (mounted) {
            context.go('/login');
          }
          return;
        }

        final userData = userDoc.data()!;
        final role = userData['role'];
        final firstName = userData['firstName'];
        final lastName = userData['lastName'];
        
        // Проверка 1: если нет role → /role-selection
        if (role == null || role.toString().isEmpty) {
          debugLog("ROLE_SELECTION_SHOWN");
          if (mounted) {
            context.go('/role-selection');
          }
          return;
        }
        
        // Проверка 2: если отсутствуют firstName или lastName → /onboarding/complete-profile
        if (firstName == null || firstName.toString().isEmpty ||
            lastName == null || lastName.toString().isEmpty) {
          debugLog("AUTH_ENRICH_PROFILE_OPENED");
          if (mounted) {
            context.go('/onboarding/complete-profile');
          }
          return;
        }
        
        // Всё готово → /main
        debugLog("HOME_LOADED");
        if (mounted) {
          context.go('/main');
        }
      } catch (e) {
        debugLog("ERROR:AUTH_GATE_CHECK:$e");
        debugLog("AUTH_SCREEN_SHOWN");
        if (mounted) {
          context.go('/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Event',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

