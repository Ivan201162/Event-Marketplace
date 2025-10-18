import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

/// Р­РєСЂР°РЅ Р·Р°РіСЂСѓР·РєРё СЃ Р°РЅРёРјР°С†РёРµР№ Рё РёРЅРёС†РёР°Р»РёР·Р°С†РёРµР№
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _progressAnimation;

  double _progress = 0;
  String _statusText = 'РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ...';
  bool _showRetryButton = false;

  @override
  void initState() {
    super.initState();
    debugPrint('рџ•ђ [${DateTime.now()}] SplashScreen.initState() called');
    _initializeAnimations();
    _initializeAppWithTimeout();
  }

  Future<void> _initializeAppWithTimeout() async {
    debugPrint('рџ•ђ [${DateTime.now()}] SplashScreen._initializeAppWithTimeout() called');
    
    // РЈСЃС‚Р°РЅР°РІР»РёРІР°РµРј С‚Р°Р№РјР°СѓС‚ РІ 10 СЃРµРєСѓРЅРґ
    final timeout = Future.delayed(const Duration(seconds: 10));
    final initialization = _initializeApp();

    try {
      await Future.any([initialization, timeout]);
      debugPrint('вњ… [${DateTime.now()}] SplashScreen initialization completed');
    } catch (e) {
      debugPrint('вќЊ [${DateTime.now()}] SplashScreen timeout or error: $e');
      // Р•СЃР»Рё РїСЂРѕРёР·РѕС€Р»Р° РѕС€РёР±РєР° РёР»Рё С‚Р°Р№РјР°СѓС‚
      if (mounted) {
        setState(() {
          _statusText = 'Р—Р°РіСЂСѓР·РєР° Р·Р°РЅРёРјР°РµС‚ Р±РѕР»СЊС€Рµ РІСЂРµРјРµРЅРё, С‡РµРј РѕР¶РёРґР°Р»РѕСЃСЊ';
          _showRetryButton = true;
        });
      }
    }
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _logoController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // РЈРїСЂРѕС‰РµРЅРЅР°СЏ РёРЅРёС†РёР°Р»РёР·Р°С†РёСЏ РґР»СЏ РґРёР°РіРЅРѕСЃС‚РёРєРё
      setState(() {
        _statusText = 'Р—Р°РіСЂСѓР·РєР° РїСЂРёР»РѕР¶РµРЅРёСЏ...';
      });
      await _updateProgress(0.3);

      // РџСЂРѕРІРµСЂРєР° Р°РІС‚РѕСЂРёР·Р°С†РёРё
      setState(() {
        _statusText = 'РџСЂРѕРІРµСЂРєР° Р°РІС‚РѕСЂРёР·Р°С†РёРё...';
      });
      await _updateProgress(0.7);

      // РџСЂРѕРІРµСЂСЏРµРј СЃРѕСЃС‚РѕСЏРЅРёРµ Р°СѓС‚РµРЅС‚РёС„РёРєР°С†РёРё
      final user = FirebaseAuth.instance.currentUser;
      await _updateProgress(0.9);

      // Р—Р°РІРµСЂС€РµРЅРёРµ
      setState(() {
        _statusText = 'Р“РѕС‚РѕРІРѕ!';
      });
      await _updateProgress(1);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _navigateBasedOnAuth(user);
      }
    } on Exception catch (e) {
      debugPrint('рџљЁ SplashScreen error: $e');
      setState(() {
        _statusText = 'РћС€РёР±РєР° РёРЅРёС†РёР°Р»РёР·Р°С†РёРё: $e';
      });

      // Р’ СЃР»СѓС‡Р°Рµ РѕС€РёР±РєРё РїРµСЂРµС…РѕРґРёРј Рє СЌРєСЂР°РЅСѓ Р°РІС‚РѕСЂРёР·Р°С†РёРё
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToAuthScreen();
      }
    }
  }

  Future<void> _updateProgress(double progress) async {
    setState(() {
      _progress = progress;
    });
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _preloadData() async {
    try {
      // Р—РґРµСЃСЊ РјРѕР¶РЅРѕ РґРѕР±Р°РІРёС‚СЊ РїСЂРµРґР·Р°РіСЂСѓР·РєСѓ РєСЂРёС‚РёС‡РµСЃРєРё РІР°Р¶РЅС‹С… РґР°РЅРЅС‹С…
      await Future.delayed(const Duration(milliseconds: 300));
    } on Exception {
      // РРіРЅРѕСЂРёСЂСѓРµРј РѕС€РёР±РєРё РїСЂРµРґР·Р°РіСЂСѓР·РєРё
    }
  }

  void _navigateBasedOnAuth(User? user) {
    debugPrint('рџ•ђ [${DateTime.now()}] SplashScreen._navigateBasedOnAuth() called, user: ${user?.uid ?? 'null'}');
    
    if (user != null) {
      // РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ Р°РІС‚РѕСЂРёР·РѕРІР°РЅ - РїРµСЂРµС…РѕРґРёРј РЅР° РіР»Р°РІРЅС‹Р№ СЌРєСЂР°РЅ
      debugPrint('рџ•ђ [${DateTime.now()}] Navigating to /main (user authenticated)');
      context.go('/main');
    } else {
      // РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ РЅРµ Р°РІС‚РѕСЂРёР·РѕРІР°РЅ - РїРµСЂРµС…РѕРґРёРј РЅР° СЌРєСЂР°РЅ Р°РІС‚РѕСЂРёР·Р°С†РёРё
      debugPrint('рџ•ђ [${DateTime.now()}] Navigating to /auth (user not authenticated)');
      context.go('/auth');
    }
  }

  void _navigateToMainScreen() {
    context.go('/main');
  }

  void _navigateToAuthScreen() {
    context.go('/auth');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('рџ•ђ [${DateTime.now()}] SplashScreen.build() called');
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Р”РёР°РіРЅРѕСЃС‚РёС‡РµСЃРєРёР№ С‚РµРєСЃС‚
            const Text(
              'вњ… App started successfully',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Status: $_statusText',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Progress: ${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            // РџСЂРѕСЃС‚РѕР№ РїСЂРѕРіСЂРµСЃСЃ-Р±Р°СЂ
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // РљРЅРѕРїРєР° РґР»СЏ РїСЂРёРЅСѓРґРёС‚РµР»СЊРЅРѕРіРѕ РїРµСЂРµС…РѕРґР°
            ElevatedButton(
              onPressed: () {
                debugPrint('рџљЂ Manual navigation to auth screen');
                _navigateToAuthScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              child: const Text('РџРµСЂРµР№С‚Рё Рє Р°РІС‚РѕСЂРёР·Р°С†РёРё'),
            ),
          ],
        ),
      ),
    );
  }
}

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СЃРѕСЃС‚РѕСЏРЅРёСЏ СЃРїР»СЌС€-СЌРєСЂР°РЅР° (РјРёРіСЂРёСЂРѕРІР°РЅ СЃ StateNotifierProvider)
final splashStateProvider =
    NotifierProvider<SplashStateNotifier, SplashState>(SplashStateNotifier.new);

class SplashState {
  const SplashState({
    this.isInitialized = false,
    this.progress = 0.0,
    this.statusText = 'РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ...',
    this.error,
  });

  final bool isInitialized;
  final double progress;
  final String statusText;
  final String? error;

  SplashState copyWith({
    bool? isInitialized,
    double? progress,
    String? statusText,
    String? error,
  }) =>
      SplashState(
        isInitialized: isInitialized ?? this.isInitialized,
        progress: progress ?? this.progress,
        statusText: statusText ?? this.statusText,
        error: error ?? this.error,
      );
}

class SplashStateNotifier extends Notifier<SplashState> {
  @override
  SplashState build() => const SplashState();

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void updateStatus(String statusText) {
    state = state.copyWith(statusText: statusText);
  }

  void setInitialized() {
    state = state.copyWith(isInitialized: true);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }
}

