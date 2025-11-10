import 'package:event_marketplace_app/core/config/app_config.dart';
import 'package:event_marketplace_app/providers/auth_providers.dart';
import 'package:event_marketplace_app/services/auth_repository.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/utils/first_run.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _googleError;
  int _logoTapCount = 0;
  bool _debugOverlayEnabled = false;

  @override
  void initState() {
    super.initState();
    // Авто-фокус на email поле
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
  
  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= 5) {
      setState(() {
        _debugOverlayEnabled = true;
        _logoTapCount = 0;
      });
      debugLog('AUTH_DEBUG_OVERLAY_ENABLED');
    }
  }

  Future<void> _signInWithEmail() async {
    // Live-валидация email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showSnack('Неверный формат email');
      return;
    }
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Заполните все поля');
      return;
    }

    debugLog('EMAIL_SIGNIN_START');
    setState(() => _isLoading = true);
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      await AuthRepository().signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      debugLog('EMAIL_SIGNIN_SUCCESS');
      if (mounted) {
        context.go('/auth-gate');
      }
    } on FirebaseAuthException catch (e) {
      debugLog('AUTH_ERR:${e.code}');
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      debugLog('AUTH_ERR:unknown:$e');
      _showSnack('Произошла ошибка. Попробуйте ещё раз');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }
  
  Future<void> _sendPasswordReset() async {
    if (_emailController.text.isEmpty) {
      _showSnack('Введите email');
      return;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showSnack('Неверный формат email');
      return;
    }
    
    try {
      await AuthRepository().sendReset(_emailController.text.trim());
      debugLog('PASSWORD_RESET_SENT:email=${_emailController.text.trim()}');
      _showSnack('Письмо для восстановления пароля отправлено на ${_emailController.text.trim()}');
    } catch (e) {
      debugLog('PASSWORD_RESET_ERROR:$e');
      _showSnack('Ошибка отправки письма. Проверьте email.');
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
      await AuthRepository().signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      debugLog('AUTH_EMAIL_SIGNUP:success');
      if (mounted) {
        context.go('/auth-gate');
      }
    } on FirebaseAuthException catch (e) {
      debugLog('AUTH_ERR:${e.code}');
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      debugLog('AUTH_ERR:unknown:$e');
      _showSnack('Произошла ошибка. Попробуйте ещё раз');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> _signInWithPhone() async {
    // Переходим на экран ввода номера телефона
    await context.push('/phone-auth');
  }

  /// Полный фикс Google Sign-In с AuthRepository и авто-повтором
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _googleError = null;
    });
    ref.read(authLoadingProvider.notifier).setLoading(true);

    try {
      await AuthRepository().signInWithGoogle();
      // дальше AuthGate отрулит
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network_request_failed' || e.code == 'unknown') {
        // один автоповтор
        try {
          await AuthRepository().signInWithGoogle();
        } catch (e2) {
          _showSnack('Ошибка входа через Google. Повторите.');
        }
      } else {
        _showSnack('Ошибка: ${e.message ?? e.code}');
      }
    } catch (e) {
      _showSnack('Не удалось войти. ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }
        
        if (shouldRetry) {
          debugLog('GOOGLE_AUTH_RETRY:code=${e.code}');
          retryAttempted = true;
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          // Повторная неудача или ошибка, которая не требует повтора
          final errorMsg = retryAttempted 
              ? 'Ошибка входа. Повторите попытку.'
              : _mappedGoogleError(e.code);
          setState(() {
            _googleError = errorMsg;
          });
          _showSnack(errorMsg);
          return;
        }
      } catch (e, st) {
        debugLog('GOOGLE_SIGNIN_ERROR:$e');
        
        // Авто-повтор для общих ошибок (один раз)
        if (!retryAttempted) {
          debugLog('GOOGLE_AUTH_RETRY:unknown_error');
          retryAttempted = true;
          await Future.delayed(const Duration(seconds: 2));
          continue;
        } else {
          final errorMsg = 'Ошибка входа. Повторите попытку.';
          setState(() {
            _googleError = errorMsg;
          });
          _showSnack(errorMsg);
          return;
        }
      }
    } finally {
      setState(() => _isLoading = false);
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  /// Маппинг ошибок Google Sign-In
  String _mappedGoogleError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение';
      case 'popup-closed-by-user':
        return 'Вход отменён';
      case 'unauthorized-domain':
        return 'Неавторизованный домен';
      case 'unknown':
        return 'Неизвестная ошибка. Попробуйте снова';
      default:
        return 'Ошибка входа. Повторите попытку.';
    }
  }

  /// Маппинг ошибок авторизации на дружелюбные сообщения
  String _mappedError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Неверный email';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'network-request-failed':
        return 'Нет соединения';
      case 'too-many-requests':
        return 'Слишком много попыток. Подождите';
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
      case 'unknown':
      case 'internal-error':
        return 'Произошла ошибка. Попробуйте ещё раз';
      default:
        return 'Произошла ошибка. Попробуйте ещё раз';
    }
  }

  /// Полная диагностика Google Sign-In
  Future<void> _runGoogleDiagnostics() async {
    debugLog('GOOGLE_DIAG:START');
    
    try {
      // packageName
      debugLog('GOOGLE_DIAG:packageName=com.eventmarketplace.app');
      
      // google-services.json
      final googleServicesPath = 'android/app/google-services.json';
      final googleServicesExists = await File(googleServicesPath).exists();
      debugLog('GOOGLE_DIAG:google_services_json:${googleServicesExists ? "found" : "not_found"}');
      
      // web client id
      final webClientId = AppConfig.webClientId;
      if (webClientId.isEmpty || webClientId.contains('REPLACE')) {
        debugLog('GOOGLE_DIAG:web_client_id:missing');
      } else {
        debugLog('GOOGLE_DIAG:web_client_id:found=${webClientId.substring(0, 30)}...');
      }
      
      // firebase options
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        debugLog('GOOGLE_DIAG:firebase_options:ok:projectId=${options.projectId}');
      } catch (e) {
        debugLog('GOOGLE_DIAG:firebase_options:error:$e');
      }
      
      // SHA1 / SHA256 (из google-services.json)
      try {
        final googleServicesFile = File(googleServicesPath);
        if (await googleServicesFile.exists()) {
          final content = await googleServicesFile.readAsString();
          if (content.contains('certificate_hash')) {
            debugLog('GOOGLE_DIAG:sha1:found_in_json');
          } else {
            debugLog('GOOGLE_DIAG:sha1:not_found_in_json');
          }
        }
      } catch (e) {
        debugLog('GOOGLE_DIAG:sha_check:error:$e');
      }
      
      // Google аккаунты в системе
      try {
        final googleSignIn = GoogleSignIn();
        final isSignedIn = await googleSignIn.isSignedIn();
        debugLog('GOOGLE_DIAG:google_accounts:isSignedIn=$isSignedIn');
        // signInSilently удалён - только ручной вход
      } catch (e) {
        debugLog('GOOGLE_DIAG:google_accounts:error:$e');
      }
      
      // Google Play Services (без signInSilently)
      if (Platform.isAndroid) {
        debugLog('GOOGLE_DIAG:google_play_services:android_detected');
        // Проверка через доступность пакета
        try {
          final googleSignIn = GoogleSignIn();
          final isSignedIn = await googleSignIn.isSignedIn();
          debugLog('GOOGLE_DIAG:google_play_services:available=${isSignedIn != null}');
        } catch (e) {
          debugLog('GOOGLE_DIAG:google_play_services:check_error:$e');
        }
      } else {
        debugLog('GOOGLE_DIAG:google_play_services:not_android');
      }
      
      debugLog('GOOGLE_DIAG:END');
      
      if (mounted) {
        _showSnack('Диагностика Google завершена. Проверьте логи.');
      }
    } catch (e) {
      debugLog('GOOGLE_DIAG:ERROR:$e');
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
      case 'invalid-email':
        return 'Неверный email';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'network-request-failed':
        return 'Нет соединения';
      case 'too-many-requests':
        return 'Слишком много попыток. Подождите';
      case 'email-already-in-use':
        return 'Этот email уже используется. Попробуйте войти или восстановить пароль.';
      case 'email-already-in-use-google':
        return 'Этот email уже используется с Google. Войти через Google?';
      case 'email-already-in-use-phone':
        return 'Этот email уже используется с номером телефона. Попробуйте войти или восстановить пароль.';
      case 'weak-password':
        return 'Пароль должен содержать минимум 6 символов';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      default:
        return 'Произошла ошибка. Попробуйте ещё раз';
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

                        // App logo and title (с обработчиком тапов для debug overlay)
                        GestureDetector(
                          onTap: _onLogoTap,
                          child: const Icon(Icons.event, size: 80, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _onLogoTap,
                          child: const Text(
                            'Event',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

                              // Email field с валидацией
                              TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                onChanged: (_) => setState(() {}), // Обновляем для валидации
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.email),
                                  errorText: _emailController.text.isNotEmpty && 
                                      !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(_emailController.text)
                                      ? 'Неверный email'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password field с кнопкой показать пароль
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _isSignUp ? _signUpWithEmail() : _signInWithEmail(),
                                onChanged: (_) => setState(() {}), // Обновляем для валидации
                                decoration: InputDecoration(
                                  labelText: 'Пароль',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  errorText: _passwordController.text.isNotEmpty && 
                                      _passwordController.text.length < 6
                                      ? 'Минимум 6 символов'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Кнопка "Забыли пароль?" (только для входа)
                              if (!_isSignUp)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading ? null : _sendPasswordReset,
                                    child: const Text('Забыли пароль?'),
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // Email auth button с прогресс-индикатором
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

                              // Debug Panic UI - красная плашка при ошибке
                              if (_googleError != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(color: Colors.red.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline, 
                                            color: Colors.red.shade700, 
                                            size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _googleError!,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Нажмите "Диагностика Google"',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // Диагностика Google кнопка (скрытая)
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: _isLoading ? null : _runGoogleDiagnostics,
                                  icon: const Icon(Icons.bug_report, size: 18),
                                  label: const Text('Диагностика Google'),
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
      
      // Debug Overlay (секретное меню)
      if (_debugOverlayEnabled)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AUTH DEBUG',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _debugOverlayEnabled = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, dynamic>>(
                  future: _getDebugInfo(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Загрузка...', style: TextStyle(color: Colors.white));
                    }
                    final info = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Firebase init: ${info['firebaseInit']}',
                            style: const TextStyle(color: Colors.white)),
                        Text('Auth state: ${info['authState']}',
                            style: const TextStyle(color: Colors.white)),
                        Text('User ID: ${info['userId']}',
                            style: const TextStyle(color: Colors.white)),
                        Text('Fresh wipe flag: ${info['freshWipe']}',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
  
  Future<Map<String, dynamic>> _getDebugInfo() async {
    try {
      final firebaseInit = Firebase.apps.isNotEmpty;
      final user = FirebaseAuth.instance.currentUser;
      final authState = user != null ? 'signed in' : 'signed out';
      final userId = user?.uid ?? 'null';
      final freshWipe = await FirstRunHelper.isFirstRun();
      
      return {
        'firebaseInit': firebaseInit,
        'authState': authState,
        'userId': userId,
        'freshWipe': freshWipe,
      };
    } catch (e) {
      return {
        'firebaseInit': 'error',
        'authState': 'error',
        'userId': 'error',
        'freshWipe': 'error',
      };
    }
  }
}
