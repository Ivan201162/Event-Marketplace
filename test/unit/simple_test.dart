import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simple Tests', () {
    test('basic math test', () {
      expect(2 + 2, equals(4));
    });

    test('string test', () {
      expect('Hello World', contains('World'));
    });

    test('list test', () {
      final list = [1, 2, 3];
      expect(list.length, equals(3));
      expect(list.first, equals(1));
      expect(list.last, equals(3));
    });
  });
}
