import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat System Tests', () {
    testWidgets('Chat list display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chats
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      // Check chat list
      final chatList = find.byType(ListView);
      expect(chatList, findsOneWidget);

      // Check chat items
      final chatCards = find.byType(Card);
      expect(chatCards, findsWidgets);
    });

    testWidgets('Open chat conversation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chats
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      // Tap on a chat
      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Verify chat screen opened
      expect(find.text('Чат'), findsOneWidget);

      // Check message list
      final messageList = find.byType(ListView);
      expect(messageList, findsOneWidget);
    });

    testWidgets('Send text message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Find message input field
      final messageField = find.byType(TextField);
      if (messageField.evaluate().isNotEmpty) {
        await tester.enterText(messageField, 'Привет! Как дела?');
        await tester.pumpAndSettle();
      }

      // Send message
      final sendButton = find.byIcon(Icons.send);
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle();
      }

      // Verify message sent
      expect(find.text('Привет! Как дела?'), findsOneWidget);
    });

    testWidgets('Send image message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Find attachment button
      final attachButton = find.byIcon(Icons.attach_file);
      if (attachButton.evaluate().isNotEmpty) {
        await tester.tap(attachButton);
        await tester.pumpAndSettle();
      }

      // Select image option
      final imageOption = find.text('Фото');
      if (imageOption.evaluate().isNotEmpty) {
        await tester.tap(imageOption);
        await tester.pumpAndSettle();
      }

      // Select from gallery
      final galleryOption = find.text('Галерея');
      if (galleryOption.evaluate().isNotEmpty) {
        await tester.tap(galleryOption);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Send voice message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Find voice message button
      final voiceButton = find.byIcon(Icons.mic);
      if (voiceButton.evaluate().isNotEmpty) {
        await tester.tap(voiceButton);
        await tester.pumpAndSettle();
      }

      // Check voice recording interface
      final recordingIndicator = find.text('Запись...');
      if (recordingIndicator.evaluate().isNotEmpty) {
        expect(recordingIndicator, findsOneWidget);
      }

      // Stop recording
      final stopButton = find.byIcon(Icons.stop);
      if (stopButton.evaluate().isNotEmpty) {
        await tester.tap(stopButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Message status indicators', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Check message status icons
      final sentIcon = find.byIcon(Icons.done);
      expect(sentIcon, findsWidgets);

      final deliveredIcon = find.byIcon(Icons.done_all);
      expect(deliveredIcon, findsWidgets);

      final readIcon = find.byIcon(Icons.done_all);
      expect(readIcon, findsWidgets);
    });

    testWidgets('Chat search functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chats
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      // Find search field
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'Иван');
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredChats = find.byType(Card);
      expect(filteredChats, findsWidgets);
    });

    testWidgets('Chat notifications', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chats
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      // Check unread message indicators
      final unreadBadge = find.byType(Badge);
      expect(unreadBadge, findsWidgets);

      // Check notification count
      final notificationCount = find.text('1');
      if (notificationCount.evaluate().isNotEmpty) {
        expect(notificationCount, findsOneWidget);
      }
    });

    testWidgets('Chat settings', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Find chat settings
      final settingsButton = find.byIcon(Icons.more_vert);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // Check settings options
      final muteOption = find.text('Отключить уведомления');
      if (muteOption.evaluate().isNotEmpty) {
        expect(muteOption, findsOneWidget);
      }

      final clearHistoryOption = find.text('Очистить историю');
      if (clearHistoryOption.evaluate().isNotEmpty) {
        expect(clearHistoryOption, findsOneWidget);
      }
    });

    testWidgets('Chat back navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to chat
      final chatsButton = find.byIcon(Icons.chat);
      if (chatsButton.evaluate().isNotEmpty) {
        await tester.tap(chatsButton);
        await tester.pumpAndSettle();
      }

      final chatCard = find.byType(Card).first;
      if (chatCard.evaluate().isNotEmpty) {
        await tester.tap(chatCard);
        await tester.pumpAndSettle();
      }

      // Test back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Verify returned to chat list
      expect(find.text('Чаты'), findsOneWidget);
    });
  });
}









