import 'package:flutter/material.dart';
import '../../services/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Неверный формат email';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'weak-password':
        return 'Пароль должен быть не менее 6 символов';
      case 'network-request-failed':
      case 'network_request_failed':
        return 'Ошибка сети. Проверьте подключение';
      case 'user-cancelled':
      case 'canceled':
      case 'popup_closed_by_user':
        return 'Вход отменён';
      default:
        return 'Ошибка входа: $code';
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Вход")),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Вход в Event Marketplace",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Неверный формат email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      if (value.length < 6) {
                        return 'Пароль должен быть не менее 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _busy ? null : _signInEmail,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Войти по Email"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _busy ? null : _signUpEmail,
                    child: const Text("Зарегистрироваться"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _busy ? null : _signInGoogle,
                    child: const Text("Войти через Google"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthRepository().signInWithEmail(emailCtrl.text.trim(), passCtrl.text);
      // Навигация происходит автоматически через StreamBuilder в AppRoot
    } on FirebaseAuthException catch (e) {
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      _showSnack("Ошибка входа: $e");
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signUpEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await AuthRepository().createUserWithEmailAndPassword(
        emailCtrl.text.trim(),
        passCtrl.text,
      );
      // Навигация происходит автоматически через StreamBuilder в AppRoot
    } on FirebaseAuthException catch (e) {
      _showSnack(_getErrorMessage(e.code));
    } catch (e) {
      _showSnack("Ошибка регистрации: $e");
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signInGoogle() async {
    developer.log('GOOGLE_BTN_TAP', name: 'LoginScreen');
    setState(() => _busy = true);
    
    bool retried = false;
    
    try {
      developer.log('GOOGLE_SIGNIN_START', name: 'LoginScreen');
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw 'USER_CANCELLED';
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('GOOGLE_FIREBASE_AUTH_START', name: 'LoginScreen');
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      developer.log('GOOGLE_SIGNIN_SUCCESS:${cred.user?.uid}', name: 'LoginScreen');
      developer.log('GOOGLE_FIREBASE_AUTH_SUCCESS:${cred.user?.uid}', name: 'LoginScreen');
      // Навигация происходит автоматически через StreamBuilder в AuthGate
    } on FirebaseAuthException catch (e, st) {
      final code = e.code;
      developer.log('GOOGLE_SIGNIN_ERROR:$code:${e.message}', name: 'LoginScreen');
      developer.log('GOOGLE_FIREBASE_AUTH_ERROR:$code:${e.message}', name: 'LoginScreen');
      
      if ((code == 'network-request-failed' || 
           code == 'network_request_failed' || 
           code == 'unknown' ||
           code == 'DEVELOPER_ERROR') && 
          !retried) {
        // Auto-retry 1 раз
        retried = true;
        try {
          final googleUser = await GoogleSignIn().signIn();
          if (googleUser == null) {
            throw 'USER_CANCELLED';
          }
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e2) {
          _showSnack("Попробуйте снова");
        }
      } else {
        _showSnack(_getErrorMessage(code));
      }
    } catch (e, st) {
      developer.log('GOOGLE_SIGNIN_ERROR:unknown:$e', name: 'LoginScreen');
      developer.log('GOOGLE_FIREBASE_AUTH_ERROR:unknown:$e', name: 'LoginScreen');
      if (!retried && (e.toString().contains('network') || e.toString().contains('unknown') || e.toString().contains('DEVELOPER_ERROR'))) {
        retried = true;
        try {
          final googleUser = await GoogleSignIn().signIn();
          if (googleUser == null) {
            throw 'USER_CANCELLED';
          }
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (e2) {
          _showSnack("Попробуйте снова");
        }
      } else {
        _showSnack("Попробуйте снова");
      }
    } finally {
      setState(() => _busy = false);
    }
  }
}
