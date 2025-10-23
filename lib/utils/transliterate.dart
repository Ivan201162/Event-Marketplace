/// Утилиты для транслитерации кириллицы в латиницу
class TransliterateUtils {
  /// Карта транслитерации кириллицы в латиницу
  static const Map<String, String> _transliterationMap = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ы': 'y', 'э': 'e', 'ю': 'yu', 'я': 'ya', 'ъ': '', 'ь': '',
    // Заглавные буквы
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D', 'Е': 'E', 'Ё': 'Yo',
    'Ж': 'Zh', 'З': 'Z', 'И': 'I', 'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M',
    'Н': 'N', 'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U',
    'Ф': 'F', 'Х': 'H', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
    'Ы': 'Y', 'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya', 'Ъ': '', 'Ь': '',
  };

  /// Транслитерирует полное имя в username
  ///
  /// Примеры:
  /// - "Иван Иванов" → "ivan_ivanov_4821"
  /// - "Анна-Мария" → "anna_mariya_7350"
  /// - "Джон Доу" → "dzhon_dou_1983"
  static String transliterateNameToUsername(String fullName) {
    if (fullName.isEmpty) {
      return _generateRandomUsername();
    }

    // Убираем лишние символы и приводим к нижнему регистру
    final cleaned = fullName.trim().toLowerCase();

    // Транслитерация
    final transliterated = cleaned
        .split('')
        .map((char) => _transliterationMap[char] ?? char)
        .join()
        .replaceAll(RegExp(r'\s+'), '_') // пробелы → _
        .replaceAll(RegExp('[-]+'), '_') // дефисы → _
        .replaceAll(RegExp('[^a-z0-9_]'), ''); // убираем всё лишнее

    // Если после транслитерации ничего не осталось, генерируем случайный username
    if (transliterated.isEmpty) {
      return _generateRandomUsername();
    }

    // Генерация случайного 4-значного суффикса
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    final suffix = random.toString().padLeft(4, '0');

    // Ограничиваем длину, чтобы не было слишком длинных юзернеймов
    final base = transliterated.length > 15
        ? transliterated.substring(0, 15)
        : transliterated;

    return '${base}_$suffix';
  }

  /// Генерирует случайный username если транслитерация не удалась
  static String _generateRandomUsername() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'user_$random';
  }

  /// Проверяет, является ли строка кириллической
  static bool isCyrillic(String text) =>
      RegExp('[а-яё]', caseSensitive: false).hasMatch(text);

  /// Транслитерирует отдельную букву
  static String transliterateChar(String char) =>
      _transliterationMap[char] ?? char;

  /// Транслитерирует текст (без генерации username)
  static String transliterateText(String text) =>
      text.split('').map((char) => _transliterationMap[char] ?? char).join();
}
