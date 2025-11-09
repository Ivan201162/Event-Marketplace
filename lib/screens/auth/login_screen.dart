import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

/// Экран входа и регистрации
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Заполните все поля');
      return;
    }

    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        context.go('/auth-gate');
      }
    } on FirebaseAuthException catch (e) {
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      _showSnack('Произошла ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showSnack('Заполните все поля');
      return;
    }

    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (mounted) {
        context.go('/auth-gate');
      }
    } on FirebaseAuthException catch (e) {
      debugLog('AUTH_ERR:${e.code}:${e.message}');
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      debugLog('AUTH_ERR:unknown:$e');
      _showSnack('Произошла ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _signInWithPhone() async {
    // Переходим на экран ввода номера телефона
    await context.push('/phone-auth');
  }

  /// Жёсткий Google Sign-In с диагностикой
  Future<void> _signInWithGoogle() async {
    debugLog('GOOGLE_BTN_TAP');
    
    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      debugLog('GOOGLE_SIGNIN_START');

      // 1) Проверка Google Play Services (через попытку инициализации)
      int googlePlayServicesStatus = -1;
      try {
        // На Android проверяем через попытку signInSilently
        if (Platform.isAndroid) {
          final googleSignIn = GoogleSignIn();
          try {
            await googleSignIn.signInSilently();
            googlePlayServicesStatus = 0; // SUCCESS
          } catch (e) {
            // Если ошибка не связана с Play Services, считаем что они доступны
            if (!e.toString().contains('SERVICE_MISSING') && 
                !e.toString().contains('SERVICE_VERSION_UPDATE_REQUIRED')) {
              googlePlayServicesStatus = 0;
            } else {
              googlePlayServicesStatus = 1; // ERROR
            }
          }
        } else {
          googlePlayServicesStatus = 0; // На других платформах считаем доступным
        }
      } catch (e) {
        debugLog('GOOGLE_PLAY_SERVICES_CHECK_ERROR:$e');
        googlePlayServicesStatus = -1;
      }
      debugLog('GOOGLE_PLAY_SERVICES:$googlePlayServicesStatus');

      // 2) Сброс предыдущих сессий
      try {
        await GoogleSignIn().signOut();
        debugLog('GOOGLE_SIGNIN_PREVIOUS_SESSION_CLEARED');
      } catch (e) {
        debugLog('GOOGLE_SIGNIN_CLEAR_ERROR:$e');
      }

      // 3) Старт браузерного флоу
      final googleUser = await GoogleSignIn(
        scopes: <String>['email', 'profile', 'openid'],
      ).signIn();

      if (googleUser == null) {
        debugLog('GOOGLE_SIGNIN_ERROR:user_cancelled');
        _showSnack('Вы отменили вход');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idTokenPreview = googleAuth.idToken?.substring(0, 20) ?? 'null';
      final accessTokenPreview = googleAuth.accessToken?.substring(0, 10) ?? 'null';
      debugLog('GOOGLE_OAUTH_TOKENS: idToken=$idTokenPreview..., access=$accessTokenPreview...');

      debugLog('GOOGLE_FIREBASE_AUTH_START');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final res = await FirebaseAuth.instance.signInWithCredential(credential);
      debugLog('GOOGLE_FIREBASE_AUTH_SUCCESS: uid=${res.user?.uid}');

      // Жёсткий редирект в AuthGate
      if (mounted) {
        context.go('/auth-gate');
      }

    } on FirebaseAuthException catch (e, st) {
      debugLog('GOOGLE_FIREBASE_AUTH_ERROR:${e.code}:${e.message}');
      debugLog('STACK:${st.toString().substring(0, st.toString().length > 800 ? 800 : st.toString().length)}');
      
      if (_shouldRetry(e.code)) {
        debugLog('GOOGLE_AUTH_RETRY');
        await Future.delayed(const Duration(seconds: 2));
        
        // ОДИН повтор
        try {
          // Сброс перед повторной попыткой
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().disconnect();
          await GoogleSignIn().signOut();
          
          // Повтор того же флоу
          final googleUser = await GoogleSignIn(
            scopes: <String>['email', 'profile', 'openid'],
          ).signIn();
          
          if (googleUser == null) {
            debugLog('GOOGLE_AUTH_RETRY:user_cancelled');
            _showSnack('Вы отменили вход');
            return;
          }
          
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          
          final res = await FirebaseAuth.instance.signInWithCredential(credential);
          debugLog('GOOGLE_FIREBASE_AUTH_RETRY_SUCCESS: uid=${res.user?.uid}');
          
          if (mounted) {
            context.go('/auth-gate');
          }
        } catch (e2, st2) {
          debugLog('GOOGLE_AUTH_RETRY_FAIL:$e2');
          debugLog('STACK_RETRY:${st2.toString().substring(0, st2.toString().length > 800 ? 800 : st2.toString().length)}');
          _showSnack('Не удалось войти через Google. Попробуйте позже.');
        }
      } else {
        _showSnack(_mapAuthError(e));
      }
    } catch (e, st) {
      debugLog('GOOGLE_SIGNIN_ERROR:$e');
      debugLog('STACK:${st.toString().substring(0, st.toString().length > 800 ? 800 : st.toString().length)}');
      _showSnack('Ошибка входа через Google.');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  /// Проверка, нужно ли повторить попытку
  bool _shouldRetry(String code) {
    return code == 'network-request-failed' || code == 'unknown';
  }

  /// Маппинг ошибок авторизации на дружелюбные сообщения
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Аккаунт с таким email уже существует с другим способом входа';
      case 'invalid-credential':
        return 'Неверные учетные данные Google';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'operation-not-allowed':
        return 'Вход через Google не разрешен';
      case 'invalid-verification-code':
        return 'Неверный код верификации';
      case 'invalid-verification-id':
        return 'Неверный ID верификации';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      case 'unknown':
        return 'Неизвестная ошибка. Попробуйте позже';
      default:
        return 'Ошибка входа: ${e.message ?? e.code}';
    }
  }

  /// Диагностика конфигурации
  Future<void> _runDiagnostics() async {
    debugLog('AUTH_DIAG:START');
    
    try {
      // applicationId
      debugLog('AUTH_DIAG:applicationId=com.eventmarketplace.app');
      
      // Google Play Services
      int gpsStatus = -1;
      try {
        if (Platform.isAndroid) {
          final googleSignIn = GoogleSignIn();
          try {
            await googleSignIn.signInSilently();
            gpsStatus = 0;
          } catch (e) {
            if (!e.toString().contains('SERVICE_MISSING') && 
                !e.toString().contains('SERVICE_VERSION_UPDATE_REQUIRED')) {
              gpsStatus = 0;
            } else {
              gpsStatus = 1;
            }
          }
        } else {
          gpsStatus = 0;
        }
      } catch (e) {
        debugLog('AUTH_DIAG:GPS_CHECK_ERROR:$e');
      }
      debugLog('AUTH_DIAG:GOOGLE_PLAY_SERVICES:$gpsStatus');
      
      // Firebase конфигурация
      try {
        final app = Firebase.app();
        debugLog('AUTH_DIAG:PROJECT_ID=${app.options.projectId}');
        debugLog('AUTH_DIAG:API_KEY=${app.options.apiKey?.substring(0, 10)}...');
        debugLog('AUTH_DIAG:APP_ID=${app.options.appId}');
      } catch (e) {
        debugLog('AUTH_DIAG:FIREBASE_CONFIG_ERROR:$e');
      }
      
      // Проверка провайдера Google
      try {
        await FirebaseAuth.instance.fetchSignInMethodsForEmail('test@example.com');
        debugLog('AUTH_DIAG:GOOGLE_PROVIDER_CHECK:ok');
      } catch (e) {
        debugLog('AUTH_DIAG:GOOGLE_PROVIDER_CHECK_ERROR:$e');
      }
      
      // Проверка Google Sign-In состояния
      try {
        final googleSignIn = GoogleSignIn();
        final isSignedIn = await googleSignIn.isSignedIn();
        debugLog('AUTH_DIAG:GOOGLE_ACCOUNT_LIST:isSignedIn=$isSignedIn');
        
        if (isSignedIn) {
          try {
            final account = await googleSignIn.signInSilently();
            debugLog('AUTH_DIAG:GOOGLE_ACCOUNT_LIST:account=${account?.email ?? "null"}');
          } catch (e) {
            debugLog('AUTH_DIAG:GOOGLE_ACCOUNT_LIST:silent_error=$e');
          }
        }
      } catch (e) {
        debugLog('AUTH_DIAG:GOOGLE_ACCOUNT_LIST_ERROR:$e');
      }
      
      debugLog('AUTH_DIAG:END');
      
      if (mounted) {
        _showSnack('Диагностика завершена. Проверьте логи.');
      }
    } catch (e) {
      debugLog('AUTH_DIAG:ERROR:$e');
      if (mounted) {
        _showSnack('Ошибка диагностики: $e');
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется. Попробуйте войти или восстановить пароль.';
      case 'email-already-in-use-google':
        return 'Этот email уже используется с Google. Войти через Google?';
      case 'email-already-in-use-phone':
        return 'Этот email уже используется с номером телефона. Попробуйте войти или восстановить пароль.';
      case 'weak-password':
        return 'Пароль должен содержать минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return 'Произошла ошибка: $errorCode';
    }
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // App logo and title
                        const Icon(Icons.event, size: 80, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Event',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Найди идеального специалиста для своего мероприятия',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),

                        const Spacer(),

                        // Auth form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Toggle between sign in and sign up
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => _isSignUp = false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isSignUp
                                            ? Colors.grey[200]
                                            : Colors.blue,
                                        foregroundColor: _isSignUp
                                            ? Colors.grey[600]
                                            : Colors.white,
                                      ),
                                      child: const Text('Вход'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          setState(() => _isSignUp = true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isSignUp
                                            ? Colors.blue
                                            : Colors.grey[200],
                                        foregroundColor: _isSignUp
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                      child: const Text('Регистрация'),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Name field (only for sign up)
                              if (_isSignUp) ...[
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Имя',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email field
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Пароль',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email auth button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : (_isSignUp
                                          ? _signUpWithEmail
                                          : _signInWithEmail),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16,),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,)
                                      : Text(_isSignUp
                                          ? 'Зарегистрироваться'
                                          : 'Войти',),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Divider
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('или'),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Phone auth button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _signInWithPhone,
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Войти по телефону'),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Google Sign-In button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _signInWithGoogle,
                                  icon: const Icon(Icons.account_circle),
                                  label: const Text('Войти через Google'),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Диагностика кнопка
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: _isLoading ? null : _runDiagnostics,
                                  icon: const Icon(Icons.bug_report, size: 18),
                                  label: const Text('Проверка конфигурации'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
