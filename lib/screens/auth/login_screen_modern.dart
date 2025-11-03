import 'package:event_marketplace_app/core/app_components.dart';
import 'package:event_marketplace_app/core/app_theme.dart';
import 'package:event_marketplace_app/core/micro_animations.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Современный экран входа с улучшенным UI/UX
class LoginScreenImproved extends ConsumerStatefulWidget {
  const LoginScreenImproved({super.key});

  @override
  ConsumerState<LoginScreenImproved> createState() =>
      _LoginScreenImprovedState();
}

class _LoginScreenImprovedState extends ConsumerState<LoginScreenImproved>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("AUTH_SCREEN_SHOWN");
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка входа через Google: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: context.isSmallScreen ? double.infinity : 400,
                          ),
                          padding: EdgeInsets.all(context.isSmallScreen ? 24 : 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Логотип и заголовок
                                Container(
                                  width: context.isSmallScreen ? 60 : 80,
                                  height: context.isSmallScreen ? 60 : 80,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.event,
                                    size: context.isSmallScreen ? 30 : 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                Text(
                                  'Добро пожаловать!',
                                  style: TextStyle(
                                    fontSize: context.isSmallScreen ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onSurfaceColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                Text(
                                  'Войдите в свой аккаунт',
                                  style: TextStyle(
                                    fontSize: context.isSmallScreen ? 14 : 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Поля ввода
                                AppComponents.animatedTextField(
                                  controller: _emailController,
                                  labelText: 'Email',
                                  hintText: 'Введите ваш email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Введите корректный email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                AppComponents.animatedTextField(
                                  controller: _passwordController,
                                  labelText: 'Пароль',
                                  hintText: 'Введите пароль',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: !_isPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите пароль';
                                    }
                                    if (value.length < 6) {
                                      return 'Пароль должен содержать минимум 6 символов';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Кнопка входа
                                SizedBox(
                                  width: double.infinity,
                                  child: MicroAnimations.loadingButton(
                                    text: 'Войти',
                                    isLoading: _isLoading,
                                    onPressed: _signInWithEmail,
                                    icon: Icons.login,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Разделитель
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'или',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Кнопка Google
                                SizedBox(
                                  width: double.infinity,
                                  child: MicroAnimations.loadingButton(
                                    text: 'Войти через Google',
                                    isLoading: _isLoading,
                                    onPressed: _signInWithGoogle,
                                    backgroundColor: Colors.white,
                                    textColor: AppTheme.onSurfaceColor,
                                    icon: Icons.g_mobiledata,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Ссылки
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Нет аккаунта? ',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.go('/register');
                                      },
                                      child: const Text('Зарегистрироваться'),
                                    ),
                                  ],
                                ),
                                
                                TextButton(
                                  onPressed: () {
                                    // TODO: Navigate to forgot password
                                  },
                                  child: const Text('Забыли пароль?'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
