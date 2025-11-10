import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/debug_log.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashEventScreen extends StatefulWidget {
  const SplashEventScreen({super.key});

  @override
  State<SplashEventScreen> createState() => _SplashEventScreenState();
}

enum SplashState {
  init,
  loading,
  ready,
  error,
}

class _SplashEventScreenState extends State<SplashEventScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  SplashState _state = SplashState.init;
  String? _error;
  DateTime? _initStartTime;
  bool _showLongLoadingMessage = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Запускаем анимацию сразу, чтобы не было чёрного экрана
    _controller.forward();
    
    _initStartTime = DateTime.now();
    _initializeFirebase();
    
    // Проверка на зависание > 8 секунд
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _state != SplashState.ready && _state != SplashState.error) {
        setState(() {
          _showLongLoadingMessage = true;
        });
      }
    });
  }

  Future<void> _initializeFirebase() async {
    debugLog("SPLASH_INIT_START");
    setState(() {
      _state = SplashState.loading;
    });
    
    try {
      // Безопасная инициализация Firebase с таймаутом
      bool firebaseInitialized = false;
      try {
        Firebase.app();
        debugLog("SPLASH_FIREBASE_ALREADY_INIT");
        firebaseInitialized = true;
      } catch (_) {
        try {
          // Инициализация Firebase с таймаутом
          await Firebase.initializeApp().timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              debugLog("SPLASH_TIMEOUT_RETRY");
              throw TimeoutException('Firebase init timeout', const Duration(seconds: 6));
            },
          );
          firebaseInitialized = true;
          debugLog("SPLASH_FIREBASE_INIT_OK");
        } on TimeoutException {
          debugLog("SPLASH_TIMEOUT_RETRY");
          // Повторная попытка
          try {
            await Firebase.initializeApp().timeout(const Duration(seconds: 4));
            firebaseInitialized = true;
            debugLog("SPLASH_FIREBASE_INIT_OK");
          } catch (e) {
            debugLog("SPLASH_INIT_FAILED:$e");
            setState(() {
              _state = SplashState.error;
              _error = e.toString();
            });
            return;
          }
        } catch (e) {
          debugLog("SPLASH_INIT_FAILED:$e");
          setState(() {
            _state = SplashState.error;
            _error = e.toString();
          });
          return;
        }
      }
      
      if (firebaseInitialized) {
        // Ждём первое событие authStateChanges с таймаутом
        try {
          await FirebaseAuth.instance.authStateChanges().timeout(
            const Duration(seconds: 6),
            onTimeout: (sink) {
              debugLog("SPLASH_AUTH_STATE_TIMEOUT");
              sink.add(null);
            },
          ).first;
          debugLog("SPLASH_AUTH_STATE_OK");
          debugLog("SPLASH_READY");
          
          setState(() {
            _state = SplashState.ready;
          });
          
          _navigateToAuthGate();
        } catch (e) {
          debugLog("SPLASH_AUTH_STATE_ERROR:$e");
          // Продолжаем даже при ошибке auth state
          setState(() {
            _state = SplashState.ready;
          });
          _navigateToAuthGate();
        }
      }
    } catch (e) {
      debugLog("SPLASH_INIT_FAILED:$e");
      setState(() {
        _state = SplashState.error;
        _error = e.toString();
      });
    }
  }

  void _navigateToAuthGate() {
    if (_state == SplashState.ready && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          context.go('/auth-gate');
        }
      });
    }
  }
  
  void _handleRetry() {
    debugLog("SPLASH:RETRY");
    setState(() {
      _state = SplashState.init;
      _error = null;
      _showLongLoadingMessage = false;
      _initStartTime = DateTime.now();
    });
    _initializeFirebase();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Если ошибка → показываем InitErrorScreen
    if (_state == SplashState.error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка инициализации',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Не удалось инициализировать приложение',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить запуск'),
              ),
            ],
          ),
        ),
      );
    }

    // Показываем splash screen
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // EVENT крупно (анимированный логотип)
                AnimatedOpacity(
                  opacity: _state == SplashState.loading ? 0.7 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'EVENT',
                    style: AppTypography.displayLg.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Тонкая черта
                Container(
                  width: 140,
                  height: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                // Слоган
                Text(
                  'Найдите своего идеального специалиста для мероприятий',
                  style: AppTypography.bodyMd.copyWith(
                    color: mutedColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_state == SplashState.loading) ...[
                  const SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (_showLongLoadingMessage) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          'Приложение загружается дольше обычного...\nПроверьте интернет.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _handleRetry,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Перезапустить'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
