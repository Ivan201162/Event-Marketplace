import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Стили приложения Event Marketplace
class AppStyles {
  // Приватный конструктор
  AppStyles._();

  // Цвета приложения
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryVariant],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, secondaryVariant],
  );

  // Тени
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Радиусы скругления
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;

  // Отступы
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;

  // Размеры иконок
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;

  // Высоты кнопок
  static const double buttonHeightSmall = 32;
  static const double buttonHeightMedium = 48;
  static const double buttonHeightLarge = 56;

  // Стили текста
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle headline5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle headline6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );

  // Стили кнопок
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium)),
    padding: const EdgeInsets.symmetric(
        horizontal: paddingLarge, vertical: paddingMedium),
    minimumSize: const Size(0, buttonHeightMedium),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium)),
    padding: const EdgeInsets.symmetric(
        horizontal: paddingLarge, vertical: paddingMedium),
    minimumSize: const Size(0, buttonHeightMedium),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium)),
    padding: const EdgeInsets.symmetric(
        horizontal: paddingMedium, vertical: paddingSmall),
    minimumSize: const Size(0, buttonHeightSmall),
  );

  // Стили карточек
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: cardShadow,
  );

  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: elevatedShadow,
  );

  // Стили полей ввода
  static InputDecoration inputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium, vertical: paddingMedium),
  );

  // Стили AppBar
  static AppBarTheme appBarTheme = const AppBarTheme(
    elevation: 0,
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black87,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  // Стили BottomNavigationBar
  static BottomNavigationBarThemeData bottomNavigationBarTheme =
      const BottomNavigationBarThemeData(
    elevation: 8,
    backgroundColor: Colors.white,
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
  );

  // Стили FloatingActionButton
  static FloatingActionButtonThemeData floatingActionButtonTheme =
      const FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 6,
  );

  // Стили Chip
  static ChipThemeData chipTheme = ChipThemeData(
    backgroundColor: Colors.grey[100],
    selectedColor: primaryColor.withValues(alpha: 0.2),
    labelStyle: bodyText2,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall)),
  );

  // Стили Card
  static CardTheme cardTheme = CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium)),
    margin: const EdgeInsets.all(paddingSmall),
  );

  // Стили Dialog
  static DialogTheme dialogTheme = DialogTheme(
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge)),
    elevation: 8,
  );

  // Стили SnackBar
  static SnackBarThemeData snackBarTheme = SnackBarThemeData(
    backgroundColor: Colors.grey[800],
    contentTextStyle: bodyText2.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall)),
    behavior: SnackBarBehavior.floating,
  );

  // Стили для темной темы
  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: Colors.grey[850],
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: cardShadow,
  );

  static BoxDecoration darkElevatedCardDecoration = BoxDecoration(
    color: Colors.grey[850],
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: elevatedShadow,
  );

  static InputDecoration darkInputDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium, vertical: paddingMedium),
    fillColor: Colors.grey[800],
    filled: true,
  );

  // Анимации
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve fastCurve = Curves.fastOutSlowIn;

  // Размеры экранов
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Утилиты для адаптивности
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  // Утилиты для отступов
  static EdgeInsets getPadding(
    BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? paddingMedium,
      vertical: vertical ?? paddingMedium,
    );
  }

  // Утилиты для размеров
  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 1.0,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint && desktop != null) {
      return width * desktop;
    } else if (width >= tabletBreakpoint && tablet != null) {
      return width * tablet;
    }
    return width * mobile;
  }

  // Утилиты для цветов
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'active':
        return successColor;
      case 'warning':
      case 'pending':
      case 'processing':
        return warningColor;
      case 'error':
      case 'failed':
      case 'cancelled':
        return errorColor;
      case 'info':
      case 'new':
        return infoColor;
      default:
        return Colors.grey;
    }
  }

  // Утилиты для градиентов
  static LinearGradient getGradientByType(String type) {
    switch (type.toLowerCase()) {
      case 'primary':
        return primaryGradient;
      case 'secondary':
        return secondaryGradient;
      default:
        return primaryGradient;
    }
  }
}
