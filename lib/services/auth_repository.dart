import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn(scopes: ['email', 'profile']);

  Future<UserCredential> signInWithGoogle() async {
    developer.log('GOOGLE_SIGNIN_START', name: 'AuthRepository');
    
    try {
      // Полный сброс состояния
      try {
        await _google.disconnect();
      } catch (_) {}
      try {
        await _google.signOut();
      } catch (_) {}

      // Этап 1: Google Sign-In
      final account = await _google.signIn();
      if (account == null) {
        developer.log('GOOGLE_SIGNIN_ERROR:canceled:User canceled', name: 'AuthRepository');
        throw FirebaseAuthException(code: 'popup_closed_by_user', message: 'Вход отменён пользователем');
      }

      developer.log('GOOGLE_SIGNIN_SUCCESS:account=${account.email}', name: 'AuthRepository');

      final auth = await account.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      // Этап 2: Firebase Auth
      developer.log('GOOGLE_FIREBASE_AUTH_START', name: 'AuthRepository');
      
      try {
        final userCred = await _auth.signInWithCredential(cred);
        developer.log('GOOGLE_FIREBASE_AUTH_SUCCESS:uid=${userCred.user?.uid}', name: 'AuthRepository');
        return userCred;
      } on FirebaseAuthException catch (e) {
        developer.log('GOOGLE_FIREBASE_AUTH_ERROR:${e.code}:${e.message}', name: 'AuthRepository');
        developer.log('GOOGLE_LOGIN_STACK:${StackTrace.current}', name: 'AuthRepository');
        rethrow;
      } catch (e, stack) {
        developer.log('GOOGLE_FIREBASE_AUTH_ERROR:unknown:$e', name: 'AuthRepository');
        developer.log('GOOGLE_LOGIN_STACK:$stack', name: 'AuthRepository');
        throw FirebaseAuthException(code: 'unknown', message: e.toString());
      }
    } on FirebaseAuthException catch (e) {
      developer.log('GOOGLE_SIGNIN_ERROR:${e.code}:${e.message}', name: 'AuthRepository');
      developer.log('GOOGLE_LOGIN_STACK:${StackTrace.current}', name: 'AuthRepository');
      rethrow;
    } catch (e, stack) {
      developer.log('GOOGLE_SIGNIN_ERROR:unknown:$e', name: 'AuthRepository');
      developer.log('GOOGLE_LOGIN_STACK:$stack', name: 'AuthRepository');
      throw FirebaseAuthException(code: 'unknown', message: e.toString());
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      developer.log('EMAIL_SIGNIN_ERROR:${e.code}:${e.message}', name: 'AuthRepository');
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Создаём базовый документ пользователя
      if (userCred.user != null) {
        await _createUserDocument(userCred.user!.uid);
      }
      
      return userCred;
    } on FirebaseAuthException catch (e) {
      developer.log('EMAIL_SIGNUP_ERROR:${e.code}:${e.message}', name: 'AuthRepository');
      rethrow;
    }
  }

  Future<void> _createUserDocument(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('CREATE_USER_DOC_ERROR:$e', name: 'AuthRepository');
    }
  }
}
