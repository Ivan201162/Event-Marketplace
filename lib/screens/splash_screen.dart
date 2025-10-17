import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Экран загрузки с анимацией и инициализацией
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
      // Упрощенная инициализация для диагностики
      setState(() {
        _statusText = 'Загрузка приложения...';
      });
      await _updateProgress(0.3);

      // Проверка авторизации
      setState(() {
        _statusText = 'Проверка авторизации...';
      });
      await _updateProgress(0.7);

      // Проверяем состояние аутентификации
      final user = FirebaseAuth.instance.currentUser;
      await _updateProgress(0.9);

      // Завершение
      setState(() {
        _statusText = 'Готово!';
      });
      await _updateProgress(1);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _navigateBasedOnAuth(user);
      }
    } on Exception catch (e) {
      debugPrint('🚨 SplashScreen error: $e');
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
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Диагностический текст
            const Text(
              '✅ App started successfully',
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
            // Простой прогресс-бар
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
            // Кнопка для принудительного перехода
            ElevatedButton(
              onPressed: () {
                debugPrint('🚀 Manual navigation to auth screen');
                _navigateToAuthScreen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              child: const Text('Перейти к авторизации'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Провайдер для состояния сплэш-экрана (мигрирован с StateNotifierProvider)
final splashStateProvider =
    NotifierProvider<SplashStateNotifier, SplashState>(SplashStateNotifier.new);

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
