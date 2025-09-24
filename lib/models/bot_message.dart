import 'package:cloud_firestore/cloud_firestore.dart';

enum BotMessageType {
  welcome,
  faq,
  support,
  booking,
  reminder,
  notification,
  help,
}

enum BotActionType {
  text,
  button,
  quickReply,
  card,
  list,
  carousel,
}

class BotAction {
  final String id;
  final String title;
  final String? payload;
  final String? url;
  final BotActionType type;
  final Map<String, dynamic> metadata;

  BotAction({
    required this.id,
    required this.title,
    this.payload,
    this.url,
    required this.type,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'payload': payload,
      'url': url,
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }

  factory BotAction.fromMap(Map<String, dynamic> map) {
    return BotAction(
      id: map['id'] as String,
      title: map['title'] as String,
      payload: map['payload'] as String?,
      url: map['url'] as String?,
      type: BotActionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class BotMessage {
  final String id;
  final String chatId;
  final BotMessageType type;
  final String text;
  final List<BotAction> actions;
  final Map<String, dynamic> metadata;
  final bool isInteractive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BotMessage({
    required this.id,
    required this.chatId,
    required this.type,
    required this.text,
    this.actions = const [],
    this.metadata = const {},
    this.isInteractive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'type': type.toString().split('.').last,
      'text': text,
      'actions': actions.map((action) => action.toMap()).toList(),
      'metadata': metadata,
      'isInteractive': isInteractive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BotMessage.fromMap(Map<String, dynamic> map) {
    return BotMessage(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      type: BotMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      text: map['text'] as String,
      actions: (map['actions'] as List<dynamic>? ?? [])
          .map((action) => BotAction.fromMap(action as Map<String, dynamic>))
          .toList(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map<String, dynamic>? ?? {}),
      isInteractive: map['isInteractive'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory BotMessage.fromDocument(DocumentSnapshot doc) {
    return BotMessage.fromMap(doc.data() as Map<String, dynamic>);
  }

  BotMessage copyWith({
    String? id,
    String? chatId,
    BotMessageType? type,
    String? text,
    List<BotAction>? actions,
    Map<String, dynamic>? metadata,
    bool? isInteractive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BotMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      text: text ?? this.text,
      actions: actions ?? this.actions,
      metadata: metadata ?? this.metadata,
      isInteractive: isInteractive ?? this.isInteractive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if bot message has interactive actions
  bool get hasActions => actions.isNotEmpty;

  /// Get quick reply actions
  List<BotAction> get quickReplyActions => 
      actions.where((action) => action.type == BotActionType.quickReply).toList();

  /// Get button actions
  List<BotAction> get buttonActions => 
      actions.where((action) => action.type == BotActionType.button).toList();
}

/// Predefined bot messages for common scenarios
class BotMessageTemplates {
  static BotMessage welcomeMessage(String chatId) {
    return BotMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      type: BotMessageType.welcome,
      text: '👋 Добро пожаловать в Event Marketplace!\n\n'
          'Я ваш помощник и готов помочь вам:\n'
          '• Найти подходящих специалистов\n'
          '• Ответить на вопросы\n'
          '• Помочь с бронированием\n'
          '• Предоставить поддержку\n\n'
          'Выберите, что вас интересует:',
      actions: [
        BotAction(
          id: 'find_specialists',
          title: '🔍 Найти специалистов',
          payload: 'find_specialists',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'faq',
          title: '❓ Частые вопросы',
          payload: 'faq',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'support',
          title: '🆘 Техподдержка',
          payload: 'support',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'booking_help',
          title: '📅 Помощь с бронированием',
          payload: 'booking_help',
          type: BotActionType.quickReply,
        ),
      ],
      isInteractive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static BotMessage faqMessage(String chatId) {
    return BotMessage(
      id: 'faq_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      type: BotMessageType.faq,
      text: '❓ Часто задаваемые вопросы:\n\n'
          '1️⃣ Как найти специалиста?\n'
          '2️⃣ Как забронировать услугу?\n'
          '3️⃣ Как отменить бронирование?\n'
          '4️⃣ Как связаться с поддержкой?\n'
          '5️⃣ Как оставить отзыв?\n\n'
          'Выберите номер вопроса для получения подробной информации:',
      actions: [
        BotAction(
          id: 'faq_1',
          title: '1️⃣ Поиск специалиста',
          payload: 'faq_1',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'faq_2',
          title: '2️⃣ Бронирование',
          payload: 'faq_2',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'faq_3',
          title: '3️⃣ Отмена бронирования',
          payload: 'faq_3',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'faq_4',
          title: '4️⃣ Поддержка',
          payload: 'faq_4',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'faq_5',
          title: '5️⃣ Отзывы',
          payload: 'faq_5',
          type: BotActionType.quickReply,
        ),
      ],
      isInteractive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static BotMessage supportMessage(String chatId) {
    return BotMessage(
      id: 'support_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      type: BotMessageType.support,
      text: '🆘 Техподдержка\n\n'
          'Для получения помощи выберите тип проблемы:',
      actions: [
        BotAction(
          id: 'support_technical',
          title: '🔧 Техническая проблема',
          payload: 'support_technical',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'support_payment',
          title: '💳 Проблема с оплатой',
          payload: 'support_payment',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'support_booking',
          title: '📅 Проблема с бронированием',
          payload: 'support_booking',
          type: BotActionType.quickReply,
        ),
        BotAction(
          id: 'support_other',
          title: '❓ Другое',
          payload: 'support_other',
          type: BotActionType.quickReply,
        ),
      ],
      isInteractive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
