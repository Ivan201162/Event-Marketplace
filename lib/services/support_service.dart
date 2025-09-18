import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/support_ticket.dart';

/// Сервис поддержки
class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;
  SupportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  /// Создать тикет поддержки
  Future<String?> createTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
    required SupportCategory category,
    SupportPriority priority = SupportPriority.medium,
    List<File>? attachments,
  }) async {
    try {
      final ticketRef = _firestore.collection('support_tickets').doc();

      // Загружаем вложения
      List<String> attachmentUrls = [];
      if (attachments != null) {
        for (File file in attachments) {
          String? url = await _uploadAttachment(file, ticketRef.id);
          if (url != null) {
            attachmentUrls.add(url);
          }
        }
      }

      // Получаем информацию об устройстве
      final deviceInfo = await _getDeviceInfo();

      final ticket = SupportTicket(
        id: ticketRef.id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        status: SupportStatus.open,
        attachments: attachmentUrls,
        metadata: deviceInfo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ticketRef.set(ticket.toMap());

      // Отправляем уведомление на email
      await _sendTicketCreatedEmail(ticket);

      return ticketRef.id;
    } catch (e) {
      print('Ошибка создания тикета поддержки: $e');
      return null;
    }
  }

  /// Получить тикеты пользователя
  Stream<List<SupportTicket>> getUserTickets(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicket.fromDocument(doc))
          .toList();
    });
  }

  /// Получить все тикеты (для админов)
  Stream<List<SupportTicket>> getAllTickets() {
    return _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicket.fromDocument(doc))
          .toList();
    });
  }

  /// Получить тикет по ID
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      final doc =
          await _firestore.collection('support_tickets').doc(ticketId).get();
      if (doc.exists) {
        return SupportTicket.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения тикета: $e');
      return null;
    }
  }

  /// Обновить тикет
  Future<bool> updateTicket(SupportTicket ticket) async {
    try {
      await _firestore
          .collection('support_tickets')
          .doc(ticket.id)
          .update(ticket.toMap());
      return true;
    } catch (e) {
      print('Ошибка обновления тикета: $e');
      return false;
    }
  }

  /// Добавить сообщение в тикет
  Future<String?> addMessage({
    required String ticketId,
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String content,
    required bool isFromSupport,
    List<File>? attachments,
  }) async {
    try {
      final messageRef = _firestore.collection('support_messages').doc();

      // Загружаем вложения
      List<String> attachmentUrls = [];
      if (attachments != null) {
        for (File file in attachments) {
          String? url = await _uploadAttachment(file, ticketId);
          if (url != null) {
            attachmentUrls.add(url);
          }
        }
      }

      final message = SupportMessage(
        id: messageRef.id,
        ticketId: ticketId,
        authorId: authorId,
        authorName: authorName,
        authorEmail: authorEmail,
        isFromSupport: isFromSupport,
        content: content,
        attachments: attachmentUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await messageRef.set(message.toMap());

      // Обновляем тикет
      final ticket = await getTicket(ticketId);
      if (ticket != null) {
        final updatedMessages = [...ticket.messages, message];
        final updatedTicket = ticket.copyWith(
          messages: updatedMessages,
          updatedAt: DateTime.now(),
        );
        await updateTicket(updatedTicket);
      }

      // Отправляем уведомление на email
      if (isFromSupport) {
        await _sendMessageNotificationEmail(ticketId, message);
      }

      return messageRef.id;
    } catch (e) {
      print('Ошибка добавления сообщения: $e');
      return null;
    }
  }

  /// Получить сообщения тикета
  Stream<List<SupportMessage>> getTicketMessages(String ticketId) {
    return _firestore
        .collection('support_messages')
        .where('ticketId', isEqualTo: ticketId)
        .orderBy('createdAt', ascending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportMessage.fromMap(doc.data()))
          .toList();
    });
  }

  /// Изменить статус тикета
  Future<bool> updateTicketStatus(String ticketId, SupportStatus status) async {
    try {
      final ticket = await getTicket(ticketId);
      if (ticket == null) return false;

      final updatedTicket = ticket.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        resolvedAt: status == SupportStatus.resolved ? DateTime.now() : null,
      );

      return await updateTicket(updatedTicket);
    } catch (e) {
      print('Ошибка обновления статуса тикета: $e');
      return false;
    }
  }

  /// Назначить тикет агенту поддержки
  Future<bool> assignTicket(
      String ticketId, String agentId, String agentName) async {
    try {
      final ticket = await getTicket(ticketId);
      if (ticket == null) return false;

      final updatedTicket = ticket.copyWith(
        assignedTo: agentId,
        assignedToName: agentName,
        status: SupportStatus.inProgress,
        updatedAt: DateTime.now(),
      );

      return await updateTicket(updatedTicket);
    } catch (e) {
      print('Ошибка назначения тикета: $e');
      return false;
    }
  }

  /// Получить FAQ
  Stream<List<FAQItem>> getFAQ({SupportCategory? category}) {
    Query query =
        _firestore.collection('faq').where('isPublished', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query
        .orderBy('viewsCount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FAQItem.fromDocument(doc)).toList();
    });
  }

  /// Увеличить счетчик просмотров FAQ
  Future<void> incrementFAQViews(String faqId) async {
    try {
      await _firestore.collection('faq').doc(faqId).update({
        'viewsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Ошибка увеличения счетчика просмотров FAQ: $e');
    }
  }

  /// Создать FAQ
  Future<String?> createFAQ({
    required String question,
    required String answer,
    required SupportCategory category,
    List<String>? tags,
  }) async {
    try {
      final faqRef = _firestore.collection('faq').doc();

      final faq = FAQItem(
        id: faqRef.id,
        question: question,
        answer: answer,
        category: category,
        tags: tags ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await faqRef.set(faq.toMap());
      return faqRef.id;
    } catch (e) {
      print('Ошибка создания FAQ: $e');
      return null;
    }
  }

  /// Получить статистику поддержки
  Future<SupportStats> getSupportStats() async {
    try {
      final snapshot = await _firestore.collection('support_tickets').get();
      final tickets =
          snapshot.docs.map((doc) => SupportTicket.fromDocument(doc)).toList();

      return _calculateSupportStats(tickets);
    } catch (e) {
      print('Ошибка получения статистики поддержки: $e');
      return SupportStats.empty();
    }
  }

  /// Загрузить вложение
  Future<String?> _uploadAttachment(File file, String ticketId) async {
    try {
      String fileName =
          'support_attachments/$ticketId/${_uuid.v4()}_${file.path.split('/').last}';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Ошибка загрузки вложения: $e');
      return null;
    }
  }

  /// Получить информацию об устройстве
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = <String, dynamic>{};

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo['platform'] = 'Android';
        deviceInfo['version'] = androidInfo.version.release;
        deviceInfo['model'] = androidInfo.model;
        deviceInfo['brand'] = androidInfo.brand;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo['platform'] = 'iOS';
        deviceInfo['version'] = iosInfo.systemVersion;
        deviceInfo['model'] = iosInfo.model;
        deviceInfo['name'] = iosInfo.name;
      } else if (Platform.isWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceInfo['platform'] = 'Web';
        deviceInfo['browser'] = webInfo.browserName.name;
        deviceInfo['version'] = webInfo.appVersion;
      }

      return deviceInfo;
    } catch (e) {
      print('Ошибка получения информации об устройстве: $e');
      return {};
    }
  }

  /// Отправить email о создании тикета
  Future<void> _sendTicketCreatedEmail(SupportTicket ticket) async {
    try {
      // TODO: Настроить SMTP сервер
      // final smtpServer = SmtpServer('smtp.gmail.com', username: 'support@example.com', password: 'password');

      // final message = Message()
      //   ..from = Address('support@example.com', 'Event Marketplace Support')
      //   ..recipients.add(ticket.userEmail)
      //   ..subject = 'Тикет поддержки создан: ${ticket.subject}'
      //   ..html = _buildTicketCreatedEmailHtml(ticket);

      // await send(message, smtpServer);
    } catch (e) {
      print('Ошибка отправки email: $e');
    }
  }

  /// Отправить уведомление о новом сообщении
  Future<void> _sendMessageNotificationEmail(
      String ticketId, SupportMessage message) async {
    try {
      // TODO: Настроить SMTP сервер
      // final smtpServer = SmtpServer('smtp.gmail.com', username: 'support@example.com', password: 'password');

      // final message = Message()
      //   ..from = Address('support@example.com', 'Event Marketplace Support')
      //   ..recipients.add(message.authorEmail)
      //   ..subject = 'Новый ответ в тикете поддержки'
      //   ..html = _buildMessageNotificationEmailHtml(ticketId, message);

      // await send(message, smtpServer);
    } catch (e) {
      print('Ошибка отправки уведомления: $e');
    }
  }

  /// Подсчитать статистику поддержки
  SupportStats _calculateSupportStats(List<SupportTicket> tickets) {
    final totalTickets = tickets.length;
    final openTickets =
        tickets.where((t) => t.status == SupportStatus.open).length;
    final inProgressTickets =
        tickets.where((t) => t.status == SupportStatus.inProgress).length;
    final resolvedTickets =
        tickets.where((t) => t.status == SupportStatus.resolved).length;
    final closedTickets =
        tickets.where((t) => t.status == SupportStatus.closed).length;

    // Среднее время решения
    double averageResolutionTime = 0.0;
    final resolvedTicketsWithTime =
        tickets.where((t) => t.resolvedAt != null).toList();
    if (resolvedTicketsWithTime.isNotEmpty) {
      final totalResolutionTime =
          resolvedTicketsWithTime.fold<int>(0, (sum, ticket) {
        return sum + ticket.resolvedAt!.difference(ticket.createdAt).inHours;
      });
      averageResolutionTime =
          totalResolutionTime / resolvedTicketsWithTime.length;
    }

    // Статистика по категориям
    final ticketsByCategory = <SupportCategory, int>{};
    for (final ticket in tickets) {
      ticketsByCategory[ticket.category] =
          (ticketsByCategory[ticket.category] ?? 0) + 1;
    }

    // Статистика по приоритетам
    final ticketsByPriority = <SupportPriority, int>{};
    for (final ticket in tickets) {
      ticketsByPriority[ticket.priority] =
          (ticketsByPriority[ticket.priority] ?? 0) + 1;
    }

    // Топ проблемы
    final issueCounts = <String, int>{};
    for (final ticket in tickets) {
      issueCounts[ticket.subject] = (issueCounts[ticket.subject] ?? 0) + 1;
    }
    final sortedIssues = issueCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIssues = sortedIssues.take(10).map((e) => e.key).toList();

    return SupportStats(
      totalTickets: totalTickets,
      openTickets: openTickets,
      inProgressTickets: inProgressTickets,
      resolvedTickets: resolvedTickets,
      closedTickets: closedTickets,
      averageResolutionTime: averageResolutionTime,
      ticketsByCategory: ticketsByCategory,
      ticketsByPriority: ticketsByPriority,
      topIssues: topIssues,
    );
  }

  /// HTML для email о создании тикета
  String _buildTicketCreatedEmailHtml(SupportTicket ticket) {
    return '''
    <html>
      <body>
        <h2>Тикет поддержки создан</h2>
        <p>Здравствуйте, ${ticket.userName}!</p>
        <p>Ваш тикет поддержки был успешно создан:</p>
        <ul>
          <li><strong>Номер тикета:</strong> ${ticket.id}</li>
          <li><strong>Тема:</strong> ${ticket.subject}</li>
          <li><strong>Категория:</strong> ${ticket.categoryText}</li>
          <li><strong>Приоритет:</strong> ${ticket.priorityText}</li>
          <li><strong>Статус:</strong> ${ticket.statusText}</li>
        </ul>
        <p>Мы свяжемся с вами в ближайшее время.</p>
        <p>С уважением,<br>Команда поддержки Event Marketplace</p>
      </body>
    </html>
    ''';
  }

  /// HTML для уведомления о новом сообщении
  String _buildMessageNotificationEmailHtml(
      String ticketId, SupportMessage message) {
    return '''
    <html>
      <body>
        <h2>Новый ответ в тикете поддержки</h2>
        <p>Здравствуйте!</p>
        <p>В вашем тикете поддержки появился новый ответ:</p>
        <div style="background-color: #f5f5f5; padding: 15px; margin: 15px 0;">
          ${message.content}
        </div>
        <p>Номер тикета: $ticketId</p>
        <p>С уважением,<br>Команда поддержки Event Marketplace</p>
      </body>
    </html>
    ''';
  }
}
