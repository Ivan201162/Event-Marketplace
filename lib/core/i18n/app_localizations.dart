import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ru')];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'home': 'Home',
      'search': 'Search',
      'bookings': 'Bookings',
      'chats': 'Chats',
      'profile': 'Profile',
      'error': 'Error',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'loading': 'Loading...',
      'success': 'Success',
      'failed': 'Failed',
      'settings': 'Settings',
      'logout': 'Logout',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'language': 'Language',
      'russian': 'Russian',
      'english': 'English',
    },
    'ru': {
      'home': 'Главная',
      'search': 'Поиск',
      'bookings': 'Бронирования',
      'chats': 'Чаты',
      'profile': 'Профиль',
      'error': 'Ошибка',
      'ok': 'ОК',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'add': 'Добавить',
      'loading': 'Загрузка...',
      'success': 'Успешно',
      'failed': 'Не удалось',
      'settings': 'Настройки',
      'logout': 'Выйти',
      'login': 'Войти',
      'register': 'Регистрация',
      'email': 'Email',
      'password': 'Пароль',
      'name': 'Имя',
      'language': 'Язык',
      'russian': 'Русский',
      'english': 'Английский',
    },
  };

  String t(String key) => _localizedValues[locale.languageCode]?[key] ?? key;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      final key = invocation.memberName
          .toString()
          .replaceFirst('Symbol("', '')
          .replaceFirst('")', '');
      return t(key);
    }
    return super.noSuchMethod(invocation);
  }

  String get home => t('home');
  String get search => t('search');
  String get bookings => t('bookings');
  String get chats => t('chats');
  String get profile => t('profile');
  String get error => t('error');
  String get ok => t('ok');
  String get cancel => t('cancel');
  String get save => t('save');
  String get delete => t('delete');
  String get edit => t('edit');
  String get add => t('add');
  String get loading => t('loading');
  String get success => t('success');
  String get failed => t('failed');
  String get settings => t('settings');
  String get logout => t('logout');
  String get login => t('login');
  String get register => t('register');
  String get email => t('email');
  String get password => t('password');
  String get name => t('name');
  String get language => t('language');
  String get russian => t('russian');
  String get english => t('english');
  String get close => t('close');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
