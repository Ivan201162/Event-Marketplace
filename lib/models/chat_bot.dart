import 'package:cloud_firestore/cloud_firestore.dart';

enum BotMessageType { text, quickReply, card, list, image }

enum BotActionType { openUrl, sendMessage, collectInfo, transferToHuman }

class ChatBotMessage {
  ChatBotMessage({
    required this.id,
    required this.chatId,
    required this.message,
    required this.type,
    this.quickReplies,
    this.cards,
    this.listItems,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
    required this.isFromBot,
  });

  factory ChatBotMessage.fromMap(Map<String, dynamic> map, String id) =>
      ChatBotMessage(
        id: id,
        chatId: map['chatId'] as String,
        message: map['message'] as String,
        type: BotMessageType.values.firstWhere(
          (e) => e.toString() == 'BotMessageType.${map['type']}',
          orElse: () => BotMessageType.text,
        ),
        quickReplies: map['quickReplies'] != null
            ? (map['quickReplies'] as List)
                .map((e) => BotQuickReply.fromMap(e as Map<String, dynamic>))
                .toList()
            : null,
        cards: map['cards'] != null
            ? (map['cards'] as List)
                .map((e) => BotCard.fromMap(e as Map<String, dynamic>))
                .toList()
            : null,
        listItems: map['listItems'] != null
            ? (map['listItems'] as List)
                .map((e) => BotListItem.fromMap(e as Map<String, dynamic>))
                .toList()
            : null,
        imageUrl: map['imageUrl'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        isFromBot: map['isFromBot'] as bool,
      );
  final String id;
  final String chatId;
  final String message;
  final BotMessageType type;
  final List<BotQuickReply>? quickReplies;
  final List<BotCard>? cards;
  final List<BotListItem>? listItems;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isFromBot;

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'message': message,
        'type': type.toString().split('.').last,
        'quickReplies': quickReplies?.map((e) => e.toMap()).toList(),
        'cards': cards?.map((e) => e.toMap()).toList(),
        'listItems': listItems?.map((e) => e.toMap()).toList(),
        'imageUrl': imageUrl,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'isFromBot': isFromBot,
      };
}

class BotQuickReply {
  BotQuickReply({
    required this.title,
    required this.payload,
    required this.actionType,
    this.actionData,
  });

  factory BotQuickReply.fromMap(Map<String, dynamic> map) => BotQuickReply(
        title: map['title'] as String,
        payload: map['payload'] as String,
        actionType: BotActionType.values.firstWhere(
          (e) => e.toString() == 'BotActionType.${map['actionType']}',
          orElse: () => BotActionType.sendMessage,
        ),
        actionData: map['actionData'] as Map<String, dynamic>?,
      );
  final String title;
  final String payload;
  final BotActionType actionType;
  final Map<String, dynamic>? actionData;

  Map<String, dynamic> toMap() => {
        'title': title,
        'payload': payload,
        'actionType': actionType.toString().split('.').last,
        'actionData': actionData,
      };
}

class BotCard {
  BotCard({required this.title, this.subtitle, this.imageUrl, this.buttons});

  factory BotCard.fromMap(Map<String, dynamic> map) => BotCard(
        title: map['title'] as String,
        subtitle: map['subtitle'] as String?,
        imageUrl: map['imageUrl'] as String?,
        buttons: map['buttons'] != null
            ? (map['buttons'] as List)
                .map((e) => BotButton.fromMap(e as Map<String, dynamic>))
                .toList()
            : null,
      );
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final List<BotButton>? buttons;

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'buttons': buttons?.map((e) => e.toMap()).toList(),
      };
}

class BotListItem {
  BotListItem({required this.title, this.subtitle, this.imageUrl, this.button});

  factory BotListItem.fromMap(Map<String, dynamic> map) => BotListItem(
        title: map['title'] as String,
        subtitle: map['subtitle'] as String?,
        imageUrl: map['imageUrl'] as String?,
        button: map['button'] != null
            ? BotButton.fromMap(map['button'] as Map<String, dynamic>)
            : null,
      );
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final BotButton? button;

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'button': button?.toMap(),
      };
}

class BotButton {
  BotButton({required this.title, required this.actionType, this.actionData});

  factory BotButton.fromMap(Map<String, dynamic> map) => BotButton(
        title: map['title'] as String,
        actionType: BotActionType.values.firstWhere(
          (e) => e.toString() == 'BotActionType.${map['actionType']}',
          orElse: () => BotActionType.sendMessage,
        ),
        actionData: map['actionData'] as Map<String, dynamic>?,
      );
  final String title;
  final BotActionType actionType;
  final Map<String, dynamic>? actionData;

  Map<String, dynamic> toMap() => {
        'title': title,
        'actionType': actionType.toString().split('.').last,
        'actionData': actionData,
      };
}

class BotConversation {
  BotConversation({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.context,
    required this.currentStep,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory BotConversation.fromMap(Map<String, dynamic> map, String id) =>
      BotConversation(
        id: id,
        chatId: map['chatId'] as String,
        userId: map['userId'] as String,
        context: map['context'] as Map<String, dynamic>,
        currentStep: map['currentStep'] as String,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        isActive: map['isActive'] as bool,
      );
  final String id;
  final String chatId;
  final String userId;
  final Map<String, dynamic> context;
  final String currentStep;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'userId': userId,
        'context': context,
        'currentStep': currentStep,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isActive': isActive,
      };
}
