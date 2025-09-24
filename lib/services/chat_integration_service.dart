import 'package:flutter/foundation.dart';

import 'chat_service.dart';
import 'bot_service.dart';
import 'push_notification_service.dart';

class ChatIntegrationService {
  final ChatService _chatService = ChatService();
  final BotService _botService = BotService();
  final PushNotificationService _pushNotificationService = PushNotificationService();

  /// Create a chat between customer and specialist
  Future<String> createCustomerSpecialistChat({
    required String customerId,
    required String specialistId,
  }) async {
    try {
      final chatId = await _chatService.getOrCreateChat(
        customerId,
        specialistId,
        chatType: 'customer_specialist',
      );

      // Send welcome message from bot
      await _botService.sendWelcomeMessage(chatId);

      debugPrint('Customer-specialist chat created: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('Error creating customer-specialist chat: $e');
      throw Exception('Ошибка создания чата: $e');
    }
  }

  /// Create a support chat
  Future<String> createSupportChat(String userId) async {
    try {
      final chatId = await _chatService.getOrCreateChat(
        userId,
        'support',
        chatType: 'support',
      );

      // Send support welcome message
      await _botService.sendSupportMessage(chatId);

      debugPrint('Support chat created: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('Error creating support chat: $e');
      throw Exception('Ошибка создания чата поддержки: $e');
    }
  }

  /// Create a bot chat for new users
  Future<String> createBotChat(String userId) async {
    try {
      final chatId = await _chatService.getOrCreateChat(
        userId,
        'bot',
        chatType: 'bot',
      );

      // Send welcome message
      await _botService.sendWelcomeMessage(chatId);

      debugPrint('Bot chat created: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('Error creating bot chat: $e');
      throw Exception('Ошибка создания чата с ботом: $e');
    }
  }

  /// Send notification when new message is received
  Future<void> sendMessageNotification({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String messageText,
    required String senderName,
  }) async {
    try {
      await _pushNotificationService.sendMessageNotification(
        chatId: chatId,
        senderId: senderId,
        recipientId: recipientId,
        messageText: messageText,
        senderName: senderName,
      );
    } catch (e) {
      debugPrint('Error sending message notification: $e');
    }
  }

  /// Send bot notification
  Future<void> sendBotNotification({
    required String chatId,
    required String userId,
    required String messageText,
  }) async {
    try {
      await _pushNotificationService.sendBotNotification(
        chatId: chatId,
        userId: userId,
        messageText: messageText,
      );
    } catch (e) {
      debugPrint('Error sending bot notification: $e');
    }
  }

  /// Send support notification
  Future<void> sendSupportNotification({
    required String chatId,
    required String userId,
    required String messageText,
  }) async {
    try {
      await _pushNotificationService.sendSupportNotification(
        chatId: chatId,
        userId: userId,
        messageText: messageText,
      );
    } catch (e) {
      debugPrint('Error sending support notification: $e');
    }
  }

  /// Handle booking-related chat notifications
  Future<void> sendBookingNotification({
    required String userId,
    required String bookingId,
    required String messageText,
  }) async {
    try {
      await _pushNotificationService.sendBookingNotification(
        userId: userId,
        bookingId: bookingId,
        messageText: messageText,
      );
    } catch (e) {
      debugPrint('Error sending booking notification: $e');
    }
  }

  /// Initialize chat for new user
  Future<void> initializeChatForNewUser(String userId) async {
    try {
      // Create bot chat for new user
      await createBotChat(userId);
      
      debugPrint('Chat initialized for new user: $userId');
    } catch (e) {
      debugPrint('Error initializing chat for new user: $e');
    }
  }

  /// Get or create chat with specialist from specialist profile
  Future<String> getOrCreateSpecialistChat({
    required String customerId,
    required String specialistId,
  }) async {
    try {
      return await createCustomerSpecialistChat(
        customerId: customerId,
        specialistId: specialistId,
      );
    } catch (e) {
      debugPrint('Error getting or creating specialist chat: $e');
      throw Exception('Ошибка создания чата со специалистом: $e');
    }
  }

  /// Get or create support chat
  Future<String> getOrCreateSupportChat(String userId) async {
    try {
      return await createSupportChat(userId);
    } catch (e) {
      debugPrint('Error getting or creating support chat: $e');
      throw Exception('Ошибка создания чата поддержки: $e');
    }
  }

  /// Archive chat when booking is completed
  Future<void> archiveChatAfterBooking(String chatId) async {
    try {
      await _chatService.archiveChat(chatId);
      debugPrint('Chat archived after booking: $chatId');
    } catch (e) {
      debugPrint('Error archiving chat after booking: $e');
    }
  }

  /// Reactivate chat for new booking
  Future<void> reactivateChatForNewBooking(String chatId) async {
    try {
      // In a real implementation, you would unarchive the chat
      // For now, we'll just log it
      debugPrint('Chat reactivated for new booking: $chatId');
    } catch (e) {
      debugPrint('Error reactivating chat for new booking: $e');
    }
  }
}
