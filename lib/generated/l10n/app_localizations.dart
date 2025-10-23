import 'package:flutter/material.dart';

class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations();
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get appTitle => 'Event Marketplace';
  String get home => 'Главная';
  String get search => 'Поиск';
  String get profile => 'Профиль';
  String get settings => 'Настройки';
  String get login => 'Войти';
  String get register => 'Регистрация';
  String get logout => 'Выйти';
  String get save => 'Сохранить';
  String get cancel => 'Отмена';
  String get delete => 'Удалить';
  String get edit => 'Редактировать';
  String get add => 'Добавить';
  String get loading => 'Загрузка...';
  String get error => 'Ошибка';
  String get success => 'Успешно';
  String get retry => 'Повторить';
  String get back => 'Назад';
  String get next => 'Далее';
  String get done => 'Готово';
  String get takePhoto => 'Сделать фото';
  String get chooseFromGallery => 'Выбрать из галереи';
  String get takeVideo => 'Снять видео';
  String get chooseVideoFromGallery => 'Выбрать видео из галереи';
  String get storyCreatedSuccessfully => 'Сторис успешно создан';
  String get errorCreatingStory => 'Ошибка создания сторис';
  String get close => 'Закрыть';
  String get ok => 'ОК';
  String get yes => 'Да';
  String get no => 'Нет';
  String get welcome => 'Добро пожаловать в Event Marketplace';
  String get bookings => 'Бронирования';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations();

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
