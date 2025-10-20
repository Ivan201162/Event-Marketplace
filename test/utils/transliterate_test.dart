import 'package:event_marketplace_app/utils/transliterate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransliterateUtils', () {
    test('transliterateNameToUsername - русские имена', () {
      final result1 = TransliterateUtils.transliterateNameToUsername('Иван Иванов');
      expect(result1, startsWith('ivan_ivanov_'));
      expect(result1, matches(RegExp(r'^ivan_ivanov_\d{4}$')));

      final result2 = TransliterateUtils.transliterateNameToUsername('Анна-Мария');
      expect(result2, startsWith('anna_mariya_'));
      expect(result2, matches(RegExp(r'^anna_mariya_\d{4}$')));

      final result3 = TransliterateUtils.transliterateNameToUsername('Джон Доу');
      expect(result3, startsWith('dzhon_dou_'));
      expect(result3, matches(RegExp(r'^dzhon_dou_\d{4}$')));
    });

    test('transliterateNameToUsername - английские имена', () {
      final result = TransliterateUtils.transliterateNameToUsername('John Doe');
      expect(result, startsWith('john_doe_'));
      expect(result, matches(RegExp(r'^john_doe_\d{4}$')));
    });

    test('transliterateNameToUsername - смешанные имена', () {
      final result = TransliterateUtils.transliterateNameToUsername('Александр Smith');
      expect(result, startsWith('aleksandr_smith_'));
      expect(result, matches(RegExp(r'^aleksandr_smith_\d{4}$')));
    });

    test('transliterateNameToUsername - пустая строка', () {
      final result = TransliterateUtils.transliterateNameToUsername('');
      expect(result, startsWith('user_'));
      expect(result, matches(RegExp(r'^user_\d+$')));
    });

    test('transliterateNameToUsername - только спецсимволы', () {
      final result = TransliterateUtils.transliterateNameToUsername(r'!@#$%^&*()');
      expect(result, startsWith('user_'));
      expect(result, matches(RegExp(r'^user_\d+$')));
    });

    test('transliterateNameToUsername - длинное имя', () {
      final result =
          TransliterateUtils.transliterateNameToUsername('ОченьДлинноеИмяКотороеПревышаетЛимит');
      expect(result, matches(RegExp(r'^[a-z_]{1,15}_\d{4}$')));
    });

    test('isCyrillic - проверка кириллицы', () {
      expect(TransliterateUtils.isCyrillic('Привет'), isTrue);
      expect(TransliterateUtils.isCyrillic('Hello'), isFalse);
      expect(TransliterateUtils.isCyrillic('Привет Hello'), isTrue);
      expect(TransliterateUtils.isCyrillic(''), isFalse);
    });

    test('transliterateChar - транслитерация отдельных букв', () {
      expect(TransliterateUtils.transliterateChar('а'), equals('a'));
      expect(TransliterateUtils.transliterateChar('А'), equals('A'));
      expect(TransliterateUtils.transliterateChar('ё'), equals('yo'));
      expect(TransliterateUtils.transliterateChar('ъ'), equals(''));
      expect(TransliterateUtils.transliterateChar('ь'), equals(''));
      expect(TransliterateUtils.transliterateChar('a'), equals('a'));
    });

    test('transliterateText - транслитерация текста', () {
      expect(TransliterateUtils.transliterateText('Привет мир'), equals('Privet mir'));
      expect(TransliterateUtils.transliterateText('Hello world'), equals('Hello world'));
      expect(TransliterateUtils.transliterateText(''), equals(''));
    });

    test('transliterateNameToUsername - уникальность суффиксов', () async {
      final results = <String>[];
      for (var i = 0; i < 10; i++) {
        results.add(TransliterateUtils.transliterateNameToUsername('Тест'));
        // Небольшая задержка для обеспечения уникальности timestamp
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Проверяем, что все результаты разные
      final uniqueResults = results.toSet();
      expect(uniqueResults.length, equals(results.length));
    });
  });
}
