import 'package:event_marketplace_app/services/navigation_service.dart';
import 'package:event_marketplace_app/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран загрузки с анимацией и проверкой сессии
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _progressAnimation;

  String _loadingText = 'Загрузка...';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoading();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ),);

    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ),);

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ),);
  }

  Future<void> _startLoading() async {
    try {
      // Запускаем анимации
      _logoController.forward();

      await Future.delayed(const Duration(milliseconds: 500));
      _textController.forward();

      await Future.delayed(const Duration(milliseconds: 300));
      _progressController.forward();

      // Симулируем прогресс загрузки
      _simulateProgress();

      // Проверяем сессию
      await _checkSession();
    } catch (e) {
      debugPrint('❌ Error in loading: $e');
      _navigateToLogin();
    }
  }

  Future<void> _simulateProgress() async {
    const steps = [
      {'text': 'Инициализация...', 'progress': 0.2},
      {'text': 'Загрузка данных...', 'progress': 0.4},
      {'text': 'Проверка сессии...', 'progress': 0.6},
      {'text': 'Настройка интерфейса...', 'progress': 0.8},
      {'text': 'Готово!', 'progress': 1.0},
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _loadingText = step['text']! as String;
          _progress = step['progress']! as double;
        });
      }
    }
  }

  Future<void> _checkSession() async {
    try {
      final hasSession = await SessionService.hasActiveSession();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (hasSession) {
          NavigationService.safeGo(context, '/main');
        } else {
          NavigationService.safeGo(context, '/login');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking session: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      NavigationService.safeGo(context, '/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип с анимацией
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.event,
                        size: 60,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Название приложения
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Event Marketplace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Платформа для организации событий',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Прогресс загрузки
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      // Текст загрузки
                      FadeTransition(
                        opacity: _textAnimation,
                        child: Text(
                          _loadingText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Прогресс-бар
                      Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progress * _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Процент загрузки
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          final percentage =
                              (_progress * _progressAnimation.value * 100)
                                  .round();
                          return Text(
                            '$percentage%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 60),

              // Индикатор загрузки
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: _progress * _progressAnimation.value,
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
