import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/cache_service.dart';

/// Экран загрузки с анимацией и инициализацией
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _progressAnimation;

  double _progress = 0;
  String _statusText = 'Инициализация...';
  bool _showRetryButton = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAppWithTimeout();
  }

  Future<void> _initializeAppWithTimeout() async {
    // Устанавливаем таймаут в 10 секунд
    final timeout = Future.delayed(const Duration(seconds: 10));
    final initialization = _initializeApp();

    try {
      await Future.any([initialization, timeout]);
    } catch (e) {
      // Если произошла ошибка или таймаут
      if (mounted) {
        setState(() {
          _statusText = 'Загрузка занимает больше времени, чем ожидалось';
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
      // Инициализация Firebase
      setState(() {
        _statusText = 'Инициализация Firebase...';
      });
      await _updateProgress(0.1);

      await Firebase.initializeApp();
      await _updateProgress(0.2);

      // Инициализация кэша
      setState(() {
        _statusText = 'Инициализация кэша...';
      });
      await _updateProgress(0.3);

      final cacheService = CacheService();
      await cacheService.initialize();
      await _updateProgress(0.5);

      // Проверка авторизации
      setState(() {
        _statusText = 'Проверка авторизации...';
      });
      await _updateProgress(0.7);

      // Проверяем состояние аутентификации
      final user = FirebaseAuth.instance.currentUser;
      await _updateProgress(0.9);

      // Предзагрузка данных
      setState(() {
        _statusText = 'Предзагрузка данных...';
      });
      await _preloadData();
      await _updateProgress(1);

      // Завершение
      setState(() {
        _statusText = 'Готово!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _navigateBasedOnAuth(user);
      }
    } on Exception catch (e) {
      setState(() {
        _statusText = 'Ошибка инициализации: $e';
      });

      // В случае ошибки переходим к экрану авторизации
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
      // Здесь можно добавить предзагрузку критически важных данных
      await Future.delayed(const Duration(milliseconds: 300));
    } on Exception {
      // Игнорируем ошибки предзагрузки
    }
  }

  void _navigateBasedOnAuth(User? user) {
    if (user != null) {
      // Пользователь авторизован - переходим на главный экран
      context.go('/main');
    } else {
      // Пользователь не авторизован - переходим на экран авторизации
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Логотип с анимацией
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) => Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.event,
                        size: 60,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Название приложения
              AnimatedBuilder(
                animation: _logoFadeAnimation,
                builder: (context, child) => Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: Text(
                    'Event Marketplace',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Подзаголовок
              AnimatedBuilder(
                animation: _logoFadeAnimation,
                builder: (context, child) => Opacity(
                  opacity: _logoFadeAnimation.value * 0.8,
                  child: Text(
                    'Найдите идеального специалиста для вашего события',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Прогресс-бар
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // Статус
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) => Opacity(
                        opacity: _progressAnimation.value,
                        child: Text(
                          _statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Прогресс-бар
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) => Opacity(
                        opacity: _progressAnimation.value,
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Процент
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) => Opacity(
                        opacity: _progressAnimation.value,
                        child: Text(
                          '${(_progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Кнопка "Повторить" (показывается при таймауте)
                    if (_showRetryButton) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showRetryButton = false;
                            _progress = 0;
                            _statusText = 'Инициализация...';
                          });
                          _initializeAppWithTimeout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Провайдер для состояния сплэш-экрана
final splashStateProvider =
    StateNotifierProvider<SplashStateNotifier, SplashState>(
        (ref) => SplashStateNotifier());

class SplashState {
  const SplashState({
    this.isInitialized = false,
    this.progress = 0.0,
    this.statusText = 'Инициализация...',
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

class SplashStateNotifier extends StateNotifier<SplashState> {
  SplashStateNotifier() : super(const SplashState());

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
