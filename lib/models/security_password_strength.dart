import 'package:freezed_annotation/freezed_annotation.dart';
import '../core/stubs/stubs.dart';

part 'security_password_strength.freezed.dart';
part 'security_password_strength.g.dart';

/// Уровень сложности пароля
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// Результат проверки сложности пароля
@freezed
class SecurityPasswordStrength with _$SecurityPasswordStrength {
  const factory SecurityPasswordStrength({
    required PasswordStrength strength,
    @Default(0) int score,
    @Default([]) List<String> suggestions,
    @Default(false) bool hasMinLength,
    @Default(false) bool hasUppercase,
    @Default(false) bool hasLowercase,
    @Default(false) bool hasNumbers,
    @Default(false) bool hasSpecialChars,
    @Default(false) bool hasNoCommonPatterns,
  }) = _SecurityPasswordStrength;

  factory SecurityPasswordStrength.fromJson(Map<String, dynamic> json) =>
      _$SecurityPasswordStrengthFromJson(json);
}
