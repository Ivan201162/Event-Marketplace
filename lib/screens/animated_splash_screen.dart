import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Анимированный экран загрузки с логотипом и fade-out переходом
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _fadeOutAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textScaleAnimation;

  bool _isInitialized = false;
  String _statusText = 'Инициализация...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    // Контроллер для логотипа (появление)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Контроллер для текста (мерцание)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Контроллер для fade-out перехода
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Анимация масштабирования логотипа
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Анимация появления логотипа
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Анимация fade-out всего экрана
    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Анимация текста (мерцание)
    _textFadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Анимация масштабирования текста
    _textScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _startInitialization() async {
    // Запускаем анимацию логотипа
    _logoController.forward();
    
    // Запускаем анимацию текста
    _textController.repeat(reverse: true);

    // Инициализация приложения
    await _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Этап 1: Инициализация
      setState(() {
        _statusText = 'Загрузка приложения...';
        _progress = 0.2;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Этап 2: Проверка авторизации
      setState(() {
        _statusText = 'Проверка авторизации...';
        _progress = 0.6;
      });
      await Future.delayed(const Duration(milliseconds: 800));

      // Этап 3: Завершение
      setState(() {
        _statusText = 'Готово!';
        _progress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      _isInitialized = true;

      // Запускаем fade-out анимацию
      await _fadeController.forward();

      // Переходим к следующему экрану
      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('❌ Ошибка инициализации: $e');
      setState(() {
        _statusText = 'Ошибка инициализации';
        _progress = 1.0;
      });
      
      // В случае ошибки переходим к экрану авторизации
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    // Переходим к экрану проверки авторизации
    context.go('/auth-check');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Темно-синий фон
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _fadeController, _textController]),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOutAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3A8A), // Темно-синий
                    Color(0xFF3B82F6), // Синий
                    Color(0xFF60A5FA), // Светло-синий
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Анимированный логотип
                    Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Opacity(
                        opacity: _logoFadeAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
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
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Анимированное название приложения
                    Transform.scale(
                      scale: _textScaleAnimation.value,
                      child: Opacity(
                        opacity: _textFadeAnimation.value,
                        child: const Text(
                          'Event Marketplace',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Анимированный статус
                    Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Прогресс-бар
                    Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Анимированный индикатор загрузки
                    Opacity(
                      opacity: _textFadeAnimation.value,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
