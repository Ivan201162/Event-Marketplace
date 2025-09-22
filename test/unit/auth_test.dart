import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/services/auth_service.dart';
import 'package:event_marketplace_app/models/user.dart' as app_user;

import 'auth_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential, FirebaseFirestore, DocumentReference, DocumentSnapshot])
void main() {
  group('AuthService Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late MockDocumentReference mockDocRef;
    late MockDocumentSnapshot mockDocSnapshot;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockDocRef = MockDocumentReference();
      mockDocSnapshot = MockDocumentSnapshot();

      authService = AuthService();
    });

    group('Регистрация пользователя', () {
      test('успешная регистрация с email и паролем', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const displayName = 'Test User';

        when(mockUser.uid).thenReturn('user123');
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn(displayName);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);

        when(mockFirestore.collection('users')).thenReturn(mockFirestore);
        when(mockFirestore.doc(any)).thenReturn(mockDocRef);
        when(mockDocRef.set(any)).thenAnswer((_) async {});

        // Act
        final result = await authService.registerWithEmailAndPassword(
          email: email,
          password: password,
          displayName: displayName,
        );

        // Assert
        expect(result, isA<app_user.User>());
        expect(result.email, equals(email));
        expect(result.displayName, equals(displayName));
        verify(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
        verify(mockDocRef.set(any)).called(1);
      });

      test('ошибка регистрации с невалидным email', () async {
        // Arrange
        const email = 'invalid-email';
        const password = 'password123';
        const displayName = 'Test User';

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ));

        // Act & Assert
        expect(
          () => authService.registerWithEmailAndPassword(
            email: email,
            password: password,
            displayName: displayName,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('ошибка регистрации со слабым паролем', () async {
        // Arrange
        const email = 'test@example.com';
        const password = '123';
        const displayName = 'Test User';

        when(mockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'weak-password',
          message: 'The password provided is too weak.',
        ));

        // Act & Assert
        expect(
          () => authService.registerWithEmailAndPassword(
            email: email,
            password: password,
            displayName: displayName,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Вход пользователя', () {
      test('успешный вход с email и паролем', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(mockUser.uid).thenReturn('user123');
        when(mockUser.email).thenReturn(email);
        when(mockUser.displayName).thenReturn('Test User');
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockUserCredential);

        when(mockFirestore.collection('users')).thenReturn(mockFirestore);
        when(mockFirestore.doc(any)).thenReturn(mockDocRef);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'id': 'user123',
          'email': email,
          'displayName': 'Test User',
          'role': 'customer',
          'createdAt': DateTime.now().toIso8601String(),
        });
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<app_user.User>());
        expect(result.email, equals(email));
        verify(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
      });

      test('ошибка входа с неверными учетными данными', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email.',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Выход пользователя', () {
      test('успешный выход', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });
    });

    group('Текущий пользователь', () {
      test('получение текущего пользователя', () async {
        // Arrange
        when(mockUser.uid).thenReturn('user123');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.displayName).thenReturn('Test User');
        when(mockAuth.currentUser).thenReturn(mockUser);

        when(mockFirestore.collection('users')).thenReturn(mockFirestore);
        when(mockFirestore.doc(any)).thenReturn(mockDocRef);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'id': 'user123',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'role': 'customer',
          'createdAt': DateTime.now().toIso8601String(),
        });
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await authService.getCurrentUser();

        // Assert
        expect(result, isA<app_user.User>());
        expect(result.email, equals('test@example.com'));
      });

      test('отсутствие текущего пользователя', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await authService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });
  });
}
