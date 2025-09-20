/// Уровень сложности пароля
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// Результат проверки сложности пароля
class SecurityPasswordStrength {
  const SecurityPasswordStrength({
    required this.strength,
    this.score = 0,
    this.suggestions = const [],
    this.hasMinLength = false,
    this.hasUppercase = false,
    this.hasLowercase = false,
    this.hasNumbers = false,
    this.hasSpecialChars = false,
    this.hasNoCommonPatterns = false,
  });

  final PasswordStrength strength;
  final int score;
  final List<String> suggestions;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumbers;
  final bool hasSpecialChars;
  final bool hasNoCommonPatterns;

  factory SecurityPasswordStrength.fromJson(Map<String, dynamic> json) =>
      SecurityPasswordStrength(
        strength: PasswordStrength.values.firstWhere(
          (e) => e.name == json['strength'],
          orElse: () => PasswordStrength.weak,
        ),
        score: json['score'] as int? ?? 0,
        suggestions:
            (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? [],
        hasMinLength: json['hasMinLength'] as bool? ?? false,
        hasUppercase: json['hasUppercase'] as bool? ?? false,
        hasLowercase: json['hasLowercase'] as bool? ?? false,
        hasNumbers: json['hasNumbers'] as bool? ?? false,
        hasSpecialChars: json['hasSpecialChars'] as bool? ?? false,
        hasNoCommonPatterns: json['hasNoCommonPatterns'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'strength': strength.name,
        'score': score,
        'suggestions': suggestions,
        'hasMinLength': hasMinLength,
        'hasUppercase': hasUppercase,
        'hasLowercase': hasLowercase,
        'hasNumbers': hasNumbers,
        'hasSpecialChars': hasSpecialChars,
        'hasNoCommonPatterns': hasNoCommonPatterns,
      };
}
