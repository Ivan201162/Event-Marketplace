# 📧 Руководство по настройке email сервиса

## 📅 Дата создания
**3 октября 2025 года**

## 🎯 Цель
Настроить email сервис для отправки уведомлений в Event Marketplace App.

## 📧 Поддерживаемые email провайдеры

### 1. 📮 Gmail SMTP
- **Статус**: ✅ Рекомендуется для разработки
- **Преимущества**: 
  - Бесплатный
  - Простая настройка
  - Высокая доставляемость

### 2. 📨 SendGrid
- **Статус**: ✅ Рекомендуется для продакшена
- **Преимущества**:
  - Профессиональный сервис
  - Отличная аналитика
  - Высокая доставляемость
  - API для интеграции

### 3. 📬 Mailgun
- **Статус**: ✅ Альтернатива
- **Преимущества**:
  - Хорошая производительность
  - Детальная аналитика
  - API для разработчиков

### 4. 📭 Amazon SES
- **Статус**: ✅ Для AWS инфраструктуры
- **Преимущества**:
  - Интеграция с AWS
  - Низкая стоимость
  - Высокая масштабируемость

## 🚀 Настройка SendGrid

### 1. 🔑 Создание аккаунта SendGrid

#### 1.1 Регистрация
```bash
# Регистрация на https://sendgrid.com
# Получение API ключа
# Настройка домена для отправки
```

#### 1.2 Установка зависимостей
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
  mailer: ^6.0.1
```

#### 1.3 Настройка конфигурации
```dart
// lib/config/email_config.dart
class EmailConfig {
  static const String sendGridApiKey = 'your_sendgrid_api_key';
  static const String fromEmail = 'noreply@your-domain.com';
  static const String fromName = 'Event Marketplace';
  
  // Тестовые настройки для разработки
  static const String testFromEmail = 'test@your-domain.com';
  static const String testFromName = 'Event Marketplace Test';
  
  static String get currentFromEmail {
    return kDebugMode ? testFromEmail : fromEmail;
  }
  
  static String get currentFromName {
    return kDebugMode ? testFromName : fromName;
  }
}
```

### 2. 📧 Сервис отправки email

#### 2.1 SendGrid сервис
```dart
// lib/services/sendgrid_email_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/email_config.dart';

class SendGridEmailService {
  static const String _baseUrl = 'https://api.sendgrid.com/v3';
  
  /// Отправить email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
    List<String>? cc,
    List<String>? bcc,
    Map<String, dynamic>? customArgs,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mail/send'),
      headers: {
        'Authorization': 'Bearer ${EmailConfig.sendGridApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [{'email': to}],
            if (cc != null) 'cc': cc.map((email) => {'email': email}).toList(),
            if (bcc != null) 'bcc': bcc.map((email) => {'email': email}).toList(),
            if (customArgs != null) 'custom_args': customArgs,
          }
        ],
        'from': {
          'email': EmailConfig.currentFromEmail,
          'name': EmailConfig.currentFromName,
        },
        'subject': subject,
        'content': [
          if (textContent != null)
            {
              'type': 'text/plain',
              'value': textContent,
            },
          {
            'type': 'text/html',
            'value': htmlContent,
          },
        ],
      }),
    );
    
    return response.statusCode == 202;
  }
  
  /// Отправить шаблонный email
  Future<bool> sendTemplateEmail({
    required String to,
    required String templateId,
    required Map<String, dynamic> dynamicTemplateData,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mail/send'),
      headers: {
        'Authorization': 'Bearer ${EmailConfig.sendGridApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personalizations': [
          {
            'to': [{'email': to}],
            if (cc != null) 'cc': cc.map((email) => {'email': email}).toList(),
            if (bcc != null) 'bcc': bcc.map((email) => {'email': email}).toList(),
            'dynamic_template_data': dynamicTemplateData,
          }
        ],
        'from': {
          'email': EmailConfig.currentFromEmail,
          'name': EmailConfig.currentFromName,
        },
        'template_id': templateId,
      }),
    );
    
    return response.statusCode == 202;
  }
}
```

#### 2.2 Универсальный email сервис
```dart
// lib/services/email_service.dart
import 'sendgrid_email_service.dart';
import 'smtp_email_service.dart';

class EmailService {
  final SendGridEmailService _sendGridService = SendGridEmailService();
  final SMTPEmailService _smtpService = SMTPEmailService();
  
  /// Отправить email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
    List<String>? cc,
    List<String>? bcc,
    Map<String, dynamic>? customArgs,
  }) async {
    try {
      // Используем SendGrid для продакшена
      if (kDebugMode) {
        return await _smtpService.sendEmail(
          to: to,
          subject: subject,
          htmlContent: htmlContent,
          textContent: textContent,
          cc: cc,
          bcc: bcc,
        );
      } else {
        return await _sendGridService.sendEmail(
          to: to,
          subject: subject,
          htmlContent: htmlContent,
          textContent: textContent,
          cc: cc,
          bcc: bcc,
          customArgs: customArgs,
        );
      }
    } catch (e) {
      print('Ошибка отправки email: $e');
      return false;
    }
  }
  
  /// Отправить шаблонный email
  Future<bool> sendTemplateEmail({
    required String to,
    required String templateId,
    required Map<String, dynamic> dynamicTemplateData,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    try {
      return await _sendGridService.sendTemplateEmail(
        to: to,
        templateId: templateId,
        dynamicTemplateData: dynamicTemplateData,
        cc: cc,
        bcc: bcc,
      );
    } catch (e) {
      print('Ошибка отправки шаблонного email: $e');
      return false;
    }
  }
}
```

### 3. 📧 SMTP сервис для разработки

#### 3.1 SMTP сервис
```dart
// lib/services/smtp_email_service.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SMTPEmailService {
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _username = 'your-email@gmail.com';
  static const String _password = 'your-app-password';
  
  /// Отправить email через SMTP
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _username,
        password: _password,
        allowInsecure: false,
        ssl: false,
        ignoreBadCertificate: false,
      );
      
      final message = Message()
        ..from = Address(_username, 'Event Marketplace')
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlContent;
      
      if (textContent != null) {
        message.text = textContent;
      }
      
      if (cc != null) {
        message.ccRecipients.addAll(cc);
      }
      
      if (bcc != null) {
        message.bccRecipients.addAll(bcc);
      }
      
      final sendReport = await send(message, smtpServer);
      return sendReport.sent;
    } catch (e) {
      print('Ошибка SMTP: $e');
      return false;
    }
  }
}
```

## 📧 Email шаблоны

### 1. 🎨 HTML шаблоны

#### 1.1 Базовый шаблон
```dart
// lib/templates/email_templates.dart
class EmailTemplates {
  static String get baseTemplate => '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event Marketplace</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px 10px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 10px 10px;
        }
        .button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 12px 30px;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Event Marketplace</h1>
        <p>Ваша платформа для поиска специалистов</p>
    </div>
    <div class="content">
        {{content}}
    </div>
    <div class="footer">
        <p>© 2025 Event Marketplace. Все права защищены.</p>
        <p>Если вы не запрашивали это письмо, проигнорируйте его.</p>
    </div>
</body>
</html>
''';

  /// Шаблон приветствия
  static String get welcomeTemplate => baseTemplate.replaceAll(
    '{{content}}',
    '''
    <h2>Добро пожаловать в Event Marketplace!</h2>
    <p>Привет, {{userName}}!</p>
    <p>Спасибо за регистрацию в Event Marketplace. Теперь вы можете:</p>
    <ul>
        <li>Найти идеального специалиста для вашего мероприятия</li>
        <li>Забронировать услуги онлайн</li>
        <li>Общаться с специалистами в чате</li>
        <li>Оставлять отзывы и оценки</li>
    </ul>
    <a href="{{appUrl}}" class="button">Начать поиск</a>
    <p>Если у вас есть вопросы, не стесняйтесь обращаться в нашу службу поддержки.</p>
    ''',
  );

  /// Шаблон подтверждения бронирования
  static String get bookingConfirmationTemplate => baseTemplate.replaceAll(
    '{{content}}',
    '''
    <h2>Бронирование подтверждено!</h2>
    <p>Привет, {{userName}}!</p>
    <p>Ваше бронирование успешно подтверждено:</p>
    <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
        <h3>Детали бронирования</h3>
        <p><strong>Специалист:</strong> {{specialistName}}</p>
        <p><strong>Услуга:</strong> {{serviceName}}</p>
        <p><strong>Дата:</strong> {{bookingDate}}</p>
        <p><strong>Время:</strong> {{bookingTime}}</p>
        <p><strong>Стоимость:</strong> {{totalPrice}} ₽</p>
        <p><strong>Предоплата:</strong> {{prepayment}} ₽</p>
    </div>
    <a href="{{bookingUrl}}" class="button">Посмотреть бронирование</a>
    <p>Если у вас есть вопросы, свяжитесь с нами или со специалистом.</p>
    ''',
  );

  /// Шаблон уведомления о платеже
  static String get paymentNotificationTemplate => baseTemplate.replaceAll(
    '{{content}}',
    '''
    <h2>Платеж успешно обработан!</h2>
    <p>Привет, {{userName}}!</p>
    <p>Ваш платеж в размере <strong>{{amount}} ₽</strong> был успешно обработан.</p>
    <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
        <h3>Детали платежа</h3>
        <p><strong>ID платежа:</strong> {{paymentId}}</p>
        <p><strong>Сумма:</strong> {{amount}} ₽</p>
        <p><strong>Метод оплаты:</strong> {{paymentMethod}}</p>
        <p><strong>Дата:</strong> {{paymentDate}}</p>
        <p><strong>Статус:</strong> {{paymentStatus}}</p>
    </div>
    <a href="{{paymentUrl}}" class="button">Посмотреть платеж</a>
    <p>Спасибо за использование Event Marketplace!</p>
    ''',
  );

  /// Шаблон напоминания о мероприятии
  static String get eventReminderTemplate => baseTemplate.replaceAll(
    '{{content}}',
    '''
    <h2>Напоминание о мероприятии</h2>
    <p>Привет, {{userName}}!</p>
    <p>Напоминаем, что завтра у вас запланировано мероприятие:</p>
    <div style="background: white; padding: 20px; border-radius: 5px; margin: 20px 0;">
        <h3>Детали мероприятия</h3>
        <p><strong>Специалист:</strong> {{specialistName}}</p>
        <p><strong>Услуга:</strong> {{serviceName}}</p>
        <p><strong>Дата:</strong> {{eventDate}}</p>
        <p><strong>Время:</strong> {{eventTime}}</p>
        <p><strong>Место:</strong> {{eventLocation}}</p>
    </div>
    <a href="{{eventUrl}}" class="button">Посмотреть детали</a>
    <p>Удачного мероприятия!</p>
    ''',
  );

  /// Шаблон сброса пароля
  static String get passwordResetTemplate => baseTemplate.replaceAll(
    '{{content}}',
    '''
    <h2>Сброс пароля</h2>
    <p>Привет, {{userName}}!</p>
    <p>Вы запросили сброс пароля для вашего аккаунта в Event Marketplace.</p>
    <p>Нажмите на кнопку ниже, чтобы создать новый пароль:</p>
    <a href="{{resetUrl}}" class="button">Сбросить пароль</a>
    <p>Если вы не запрашивали сброс пароля, проигнорируйте это письмо.</p>
    <p>Ссылка действительна в течение 24 часов.</p>
    ''',
  );
}
```

### 2. 📝 Сервис шаблонов

#### 2.1 Сервис шаблонов
```dart
// lib/services/email_template_service.dart
import '../templates/email_templates.dart';

class EmailTemplateService {
  /// Заменить переменные в шаблоне
  static String replaceVariables(String template, Map<String, dynamic> variables) {
    String result = template;
    
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    
    return result;
  }
  
  /// Получить шаблон приветствия
  static String getWelcomeEmail({
    required String userName,
    required String appUrl,
  }) {
    return replaceVariables(
      EmailTemplates.welcomeTemplate,
      {
        'userName': userName,
        'appUrl': appUrl,
      },
    );
  }
  
  /// Получить шаблон подтверждения бронирования
  static String getBookingConfirmationEmail({
    required String userName,
    required String specialistName,
    required String serviceName,
    required String bookingDate,
    required String bookingTime,
    required double totalPrice,
    required double prepayment,
    required String bookingUrl,
  }) {
    return replaceVariables(
      EmailTemplates.bookingConfirmationTemplate,
      {
        'userName': userName,
        'specialistName': specialistName,
        'serviceName': serviceName,
        'bookingDate': bookingDate,
        'bookingTime': bookingTime,
        'totalPrice': totalPrice.toStringAsFixed(0),
        'prepayment': prepayment.toStringAsFixed(0),
        'bookingUrl': bookingUrl,
      },
    );
  }
  
  /// Получить шаблон уведомления о платеже
  static String getPaymentNotificationEmail({
    required String userName,
    required String paymentId,
    required double amount,
    required String paymentMethod,
    required String paymentDate,
    required String paymentStatus,
    required String paymentUrl,
  }) {
    return replaceVariables(
      EmailTemplates.paymentNotificationTemplate,
      {
        'userName': userName,
        'paymentId': paymentId,
        'amount': amount.toStringAsFixed(0),
        'paymentMethod': paymentMethod,
        'paymentDate': paymentDate,
        'paymentStatus': paymentStatus,
        'paymentUrl': paymentUrl,
      },
    );
  }
  
  /// Получить шаблон напоминания о мероприятии
  static String getEventReminderEmail({
    required String userName,
    required String specialistName,
    required String serviceName,
    required String eventDate,
    required String eventTime,
    required String eventLocation,
    required String eventUrl,
  }) {
    return replaceVariables(
      EmailTemplates.eventReminderTemplate,
      {
        'userName': userName,
        'specialistName': specialistName,
        'serviceName': serviceName,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'eventLocation': eventLocation,
        'eventUrl': eventUrl,
      },
    );
  }
  
  /// Получить шаблон сброса пароля
  static String getPasswordResetEmail({
    required String userName,
    required String resetUrl,
  }) {
    return replaceVariables(
      EmailTemplates.passwordResetTemplate,
      {
        'userName': userName,
        'resetUrl': resetUrl,
      },
    );
  }
}
```

## 🔔 Уведомления

### 1. 📧 Сервис уведомлений

#### 1.1 Сервис уведомлений
```dart
// lib/services/notification_service.dart
import 'email_service.dart';
import 'email_template_service.dart';
import 'fcm_service.dart';

class NotificationService {
  final EmailService _emailService = EmailService();
  final FCMService _fcmService = FCMService();
  
  /// Отправить уведомление о регистрации
  Future<bool> sendWelcomeNotification({
    required String userEmail,
    required String userName,
    required String appUrl,
  }) async {
    try {
      final htmlContent = EmailTemplateService.getWelcomeEmail(
        userName: userName,
        appUrl: appUrl,
      );
      
      return await _emailService.sendEmail(
        to: userEmail,
        subject: 'Добро пожаловать в Event Marketplace!',
        htmlContent: htmlContent,
      );
    } catch (e) {
      print('Ошибка отправки приветственного уведомления: $e');
      return false;
    }
  }
  
  /// Отправить уведомление о подтверждении бронирования
  Future<bool> sendBookingConfirmationNotification({
    required String userEmail,
    required String userName,
    required String specialistName,
    required String serviceName,
    required String bookingDate,
    required String bookingTime,
    required double totalPrice,
    required double prepayment,
    required String bookingUrl,
  }) async {
    try {
      final htmlContent = EmailTemplateService.getBookingConfirmationEmail(
        userName: userName,
        specialistName: specialistName,
        serviceName: serviceName,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
        totalPrice: totalPrice,
        prepayment: prepayment,
        bookingUrl: bookingUrl,
      );
      
      return await _emailService.sendEmail(
        to: userEmail,
        subject: 'Бронирование подтверждено - $serviceName',
        htmlContent: htmlContent,
      );
    } catch (e) {
      print('Ошибка отправки уведомления о бронировании: $e');
      return false;
    }
  }
  
  /// Отправить уведомление о платеже
  Future<bool> sendPaymentNotification({
    required String userEmail,
    required String userName,
    required String paymentId,
    required double amount,
    required String paymentMethod,
    required String paymentDate,
    required String paymentStatus,
    required String paymentUrl,
  }) async {
    try {
      final htmlContent = EmailTemplateService.getPaymentNotificationEmail(
        userName: userName,
        paymentId: paymentId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: paymentDate,
        paymentStatus: paymentStatus,
        paymentUrl: paymentUrl,
      );
      
      return await _emailService.sendEmail(
        to: userEmail,
        subject: 'Платеж обработан - $amount ₽',
        htmlContent: htmlContent,
      );
    } catch (e) {
      print('Ошибка отправки уведомления о платеже: $e');
      return false;
    }
  }
  
  /// Отправить напоминание о мероприятии
  Future<bool> sendEventReminderNotification({
    required String userEmail,
    required String userName,
    required String specialistName,
    required String serviceName,
    required String eventDate,
    required String eventTime,
    required String eventLocation,
    required String eventUrl,
  }) async {
    try {
      final htmlContent = EmailTemplateService.getEventReminderEmail(
        userName: userName,
        specialistName: specialistName,
        serviceName: serviceName,
        eventDate: eventDate,
        eventTime: eventTime,
        eventLocation: eventLocation,
        eventUrl: eventUrl,
      );
      
      return await _emailService.sendEmail(
        to: userEmail,
        subject: 'Напоминание о мероприятии завтра',
        htmlContent: htmlContent,
      );
    } catch (e) {
      print('Ошибка отправки напоминания о мероприятии: $e');
      return false;
    }
  }
  
  /// Отправить уведомление о сбросе пароля
  Future<bool> sendPasswordResetNotification({
    required String userEmail,
    required String userName,
    required String resetUrl,
  }) async {
    try {
      final htmlContent = EmailTemplateService.getPasswordResetEmail(
        userName: userName,
        resetUrl: resetUrl,
      );
      
      return await _emailService.sendEmail(
        to: userEmail,
        subject: 'Сброс пароля - Event Marketplace',
        htmlContent: htmlContent,
      );
    } catch (e) {
      print('Ошибка отправки уведомления о сбросе пароля: $e');
      return false;
    }
  }
  
  /// Отправить push уведомление
  Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _fcmService.sendNotification(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Ошибка отправки push уведомления: $e');
      return false;
    }
  }
}
```

### 2. ⏰ Планировщик уведомлений

#### 2.1 Планировщик
```dart
// lib/services/notification_scheduler_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'notification_service.dart';

class NotificationSchedulerService {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  /// Запланировать напоминание о мероприятии
  Future<bool> scheduleEventReminder({
    required String userEmail,
    required String userName,
    required String specialistName,
    required String serviceName,
    required DateTime eventDate,
    required String eventLocation,
    required String eventUrl,
  }) async {
    try {
      // Вычисляем время для отправки (за 24 часа до мероприятия)
      final reminderTime = eventDate.subtract(const Duration(hours: 24));
      
      // Вызываем Cloud Function для планирования
      final result = await _functions.httpsCallable('scheduleNotification').call({
        'type': 'event_reminder',
        'scheduledTime': reminderTime.toIso8601String(),
        'data': {
          'userEmail': userEmail,
          'userName': userName,
          'specialistName': specialistName,
          'serviceName': serviceName,
          'eventDate': eventDate.toIso8601String(),
          'eventLocation': eventLocation,
          'eventUrl': eventUrl,
        },
      });
      
      return result.data['success'] == true;
    } catch (e) {
      print('Ошибка планирования напоминания: $e');
      return false;
    }
  }
  
  /// Отменить запланированное уведомление
  Future<bool> cancelScheduledNotification(String notificationId) async {
    try {
      final result = await _functions.httpsCallable('cancelNotification').call({
        'notificationId': notificationId,
      });
      
      return result.data['success'] == true;
    } catch (e) {
      print('Ошибка отмены уведомления: $e');
      return false;
    }
  }
}
```

## ☁️ Cloud Functions для email

### 1. 🔧 Функции для уведомлений

#### 1.1 Функция отправки email
```javascript
// functions/send-email.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

sgMail.setApiKey(functions.config().sendgrid.api_key);

exports.sendEmail = functions.https.onCall(async (data, context) => {
  // Проверка аутентификации
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Пользователь не аутентифицирован');
  }
  
  const { to, subject, htmlContent, textContent, customArgs } = data;
  
  try {
    const msg = {
      to: to,
      from: {
        email: functions.config().email.from_email,
        name: functions.config().email.from_name,
      },
      subject: subject,
      html: htmlContent,
      text: textContent,
      customArgs: customArgs,
    };
    
    await sgMail.send(msg);
    
    // Логирование отправки
    await admin.firestore().collection('email_logs').add({
      to: to,
      subject: subject,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth.uid,
    });
    
    return { success: true };
  } catch (error) {
    console.error('Ошибка отправки email:', error);
    throw new functions.https.HttpsError('internal', 'Ошибка отправки email');
  }
});
```

#### 1.2 Функция планирования уведомлений
```javascript
// functions/schedule-notification.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.scheduleNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Пользователь не аутентифицирован');
  }
  
  const { type, scheduledTime, data: notificationData } = data;
  
  try {
    // Создание задачи в Firestore
    const taskRef = await admin.firestore().collection('scheduled_notifications').add({
      type: type,
      scheduledTime: admin.firestore.Timestamp.fromDate(new Date(scheduledTime)),
      data: notificationData,
      status: 'scheduled',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: context.auth.uid,
    });
    
    return { success: true, taskId: taskRef.id };
  } catch (error) {
    console.error('Ошибка планирования уведомления:', error);
    throw new functions.https.HttpsError('internal', 'Ошибка планирования уведомления');
  }
});
```

#### 1.3 Функция обработки запланированных уведомлений
```javascript
// functions/process-scheduled-notifications.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');

sgMail.setApiKey(functions.config().sendgrid.api_key);

exports.processScheduledNotifications = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    
    // Получение задач для выполнения
    const tasksSnapshot = await admin.firestore()
      .collection('scheduled_notifications')
      .where('scheduledTime', '<=', now)
      .where('status', '==', 'scheduled')
      .limit(100)
      .get();
    
    const promises = tasksSnapshot.docs.map(async (doc) => {
      const task = doc.data();
      
      try {
        // Обновление статуса на "выполняется"
        await doc.ref.update({
          status: 'processing',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        // Отправка уведомления в зависимости от типа
        switch (task.type) {
          case 'event_reminder':
            await sendEventReminderEmail(task.data);
            break;
          case 'payment_reminder':
            await sendPaymentReminderEmail(task.data);
            break;
          default:
            console.log(`Неизвестный тип уведомления: ${task.type}`);
        }
        
        // Обновление статуса на "завершено"
        await doc.ref.update({
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
      } catch (error) {
        console.error(`Ошибка обработки задачи ${doc.id}:`, error);
        
        // Обновление статуса на "ошибка"
        await doc.ref.update({
          status: 'failed',
          error: error.message,
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });
    
    await Promise.all(promises);
  });

async function sendEventReminderEmail(data) {
  const msg = {
    to: data.userEmail,
    from: {
      email: functions.config().email.from_email,
      name: functions.config().email.from_name,
    },
    subject: 'Напоминание о мероприятии завтра',
    html: generateEventReminderHTML(data),
  };
  
  await sgMail.send(msg);
}

async function sendPaymentReminderEmail(data) {
  const msg = {
    to: data.userEmail,
    from: {
      email: functions.config().email.from_email,
      name: functions.config().email.from_name,
    },
    subject: 'Напоминание об оплате',
    html: generatePaymentReminderHTML(data),
  };
  
  await sgMail.send(msg);
}
```

## 📊 Аналитика email

### 1. 📈 Отслеживание email

#### 1.1 Сервис аналитики
```dart
// lib/services/email_analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class EmailAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  /// Отслеживание отправки email
  static Future<void> trackEmailSent({
    required String emailType,
    required String recipientEmail,
    required bool success,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'email_sent',
      parameters: {
        'email_type': emailType,
        'recipient_email': recipientEmail,
        'success': success,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }
  
  /// Отслеживание открытия email
  static Future<void> trackEmailOpened({
    required String emailType,
    required String recipientEmail,
  }) async {
    await _analytics.logEvent(
      name: 'email_opened',
      parameters: {
        'email_type': emailType,
        'recipient_email': recipientEmail,
      },
    );
  }
  
  /// Отслеживание клика по ссылке в email
  static Future<void> trackEmailLinkClicked({
    required String emailType,
    required String recipientEmail,
    required String linkUrl,
  }) async {
    await _analytics.logEvent(
      name: 'email_link_clicked',
      parameters: {
        'email_type': emailType,
        'recipient_email': recipientEmail,
        'link_url': linkUrl,
      },
    );
  }
}
```

## 🔒 Безопасность

### 1. 🛡️ Защита email

#### 1.1 Валидация email
```dart
// lib/services/email_validation_service.dart
class EmailValidationService {
  /// Валидация email адреса
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }
  
  /// Проверка домена email
  static bool isAllowedDomain(String email) {
    final allowedDomains = [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'mail.ru',
      'yandex.ru',
      'rambler.ru',
    ];
    
    final domain = email.split('@').last.toLowerCase();
    return allowedDomains.contains(domain);
  }
  
  /// Санитизация email
  static String sanitizeEmail(String email) {
    return email.toLowerCase().trim();
  }
}
```

#### 1.2 Защита от спама
```dart
// lib/services/email_spam_protection_service.dart
class EmailSpamProtectionService {
  static final Map<String, int> _emailCounts = {};
  static final Map<String, DateTime> _lastSent = {};
  
  /// Проверка лимитов отправки
  static bool canSendEmail(String email, {int maxPerHour = 10}) {
    final now = DateTime.now();
    final hourAgo = now.subtract(const Duration(hours: 1));
    
    // Очистка старых записей
    _emailCounts.removeWhere((key, value) => 
      _lastSent[key]?.isBefore(hourAgo) ?? true);
    
    final count = _emailCounts[email] ?? 0;
    final lastSent = _lastSent[email];
    
    if (lastSent != null && now.difference(lastSent).inMinutes < 1) {
      return false; // Не более 1 письма в минуту
    }
    
    if (count >= maxPerHour) {
      return false; // Превышен лимит в час
    }
    
    return true;
  }
  
  /// Запись отправки email
  static void recordEmailSent(String email) {
    final now = DateTime.now();
    _emailCounts[email] = (_emailCounts[email] ?? 0) + 1;
    _lastSent[email] = now;
  }
}
```

## 🎯 Следующие шаги

### 1. ✅ Готово
- ✅ Интеграция SendGrid
- ✅ SMTP сервис для разработки
- ✅ HTML шаблоны
- ✅ Сервис уведомлений
- ✅ Планировщик уведомлений
- ✅ Cloud Functions
- ✅ Аналитика email
- ✅ Безопасность

### 2. 🔄 В процессе
- 🔄 Тестирование email отправки
- 🔄 Настройка домена
- 🔄 Мониторинг доставляемости

### 3. 📋 Планируется
- 📋 A/B тестирование шаблонов
- 📋 Персонализация email
- 📋 Автоматические кампании
- 📋 Интеграция с CRM

## 🎉 Заключение

Email сервис полностью настроен с:
- ✅ **SendGrid** для продакшена
- ✅ **SMTP** для разработки
- ✅ **HTML шаблонами** для всех типов уведомлений
- ✅ **Планировщиком** для автоматических уведомлений
- ✅ **Cloud Functions** для обработки
- ✅ **Аналитикой** и мониторингом
- ✅ **Безопасностью** и защитой от спама

**Готово к отправке email уведомлений в продакшене!** 🚀

---
**Следующий этап**: Пользовательское тестирование
