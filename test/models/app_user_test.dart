import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser Model Tests', () {
    test('fromMap with missing city should not crash', () {
      final data = {
        'email': 'test@example.com',
        'displayName': 'Test User',
        'role': 'customer',
        'createdAt': Timestamp.now(),
      };

      final user = AppUser.fromMap(data, 'test-uid');

      expect(user.id, 'test-uid');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.city, isNull);
      expect(user.region, isNull);
      expect(user.avatarUrl, isNull);
    });

    test('fromMap with city should parse correctly', () {
      final data = {
        'email': 'test@example.com',
        'displayName': 'Test User',
        'role': 'customer',
        'createdAt': Timestamp.now(),
        'city': 'Москва',
        'region': 'Московская область',
        'avatarUrl': 'https://example.com/avatar.jpg',
      };

      final user = AppUser.fromMap(data, 'test-uid');

      expect(user.city, 'Москва');
      expect(user.region, 'Московская область');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('toMap should not include empty fields', () {
      final user = AppUser(
        id: 'test-uid',
        email: 'test@example.com',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        region: '',
        avatarUrl: '   ',
      );

      final map = user.toMap();

      expect(map.containsKey('city'), isFalse);
      expect(map.containsKey('region'), isFalse);
      expect(map.containsKey('avatarUrl'), isFalse);
      expect(map['email'], 'test@example.com');
    });

    test('toMap should include non-empty fields', () {
      final user = AppUser(
        id: 'test-uid',
        email: 'test@example.com',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        city: 'Москва',
        region: 'Московская область',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final map = user.toMap();

      expect(map['city'], 'Москва');
      expect(map['region'], 'Московская область');
      expect(map['avatarUrl'], 'https://example.com/avatar.jpg');
    });

    test('copyWith should update fields correctly', () {
      final user = AppUser(
        id: 'test-uid',
        email: 'test@example.com',
        role: UserRole.customer,
        createdAt: DateTime.now(),
        city: 'Москва',
      );

      final updatedUser = user.copyWith(city: 'Санкт-Петербург', region: 'Ленинградская область');

      expect(updatedUser.city, 'Санкт-Петербург');
      expect(updatedUser.region, 'Ленинградская область');
      expect(updatedUser.email, 'test@example.com'); // unchanged
    });
  });
}
