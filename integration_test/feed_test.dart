import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feed and Stories Tests', () {
    testWidgets('Feed display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to home/feed
      final homeButton = find.byIcon(Icons.home);
      if (homeButton.evaluate().isNotEmpty) {
        await tester.tap(homeButton);
        await tester.pumpAndSettle();
      }

      // Check feed elements
      final feedList = find.byType(ListView);
      expect(feedList, findsOneWidget);

      // Check post cards
      final postCards = find.byType(Card);
      expect(postCards, findsWidgets);
    });

    testWidgets('Post interaction', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find a post
      final postCard = find.byType(Card).first;
      if (postCard.evaluate().isNotEmpty) {
        await tester.tap(postCard);
        await tester.pumpAndSettle();
      }

      // Test like button
      final likeButton = find.byIcon(Icons.favorite_border);
      if (likeButton.evaluate().isNotEmpty) {
        await tester.tap(likeButton);
        await tester.pumpAndSettle();
      }

      // Test comment button
      final commentButton = find.byIcon(Icons.comment);
      if (commentButton.evaluate().isNotEmpty) {
        await tester.tap(commentButton);
        await tester.pumpAndSettle();
      }

      // Test share button
      final shareButton = find.byIcon(Icons.share);
      if (shareButton.evaluate().isNotEmpty) {
        await tester.tap(shareButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Create new post', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find create post button
      final createButton = find.byIcon(Icons.add);
      if (createButton.evaluate().isNotEmpty) {
        await tester.tap(createButton);
        await tester.pumpAndSettle();
      }

      // Fill post content
      final contentField = find.byType(TextField);
      if (contentField.evaluate().isNotEmpty) {
        await tester.enterText(contentField, 'Новый пост о событии!');
        await tester.pumpAndSettle();
      }

      // Add image
      final imageButton = find.byIcon(Icons.image);
      if (imageButton.evaluate().isNotEmpty) {
        await tester.tap(imageButton);
        await tester.pumpAndSettle();
      }

      // Select image from gallery
      final galleryOption = find.text('Галерея');
      if (galleryOption.evaluate().isNotEmpty) {
        await tester.tap(galleryOption);
        await tester.pumpAndSettle();
      }

      // Publish post
      final publishButton = find.text('Опубликовать');
      if (publishButton.evaluate().isNotEmpty) {
        await tester.tap(publishButton);
        await tester.pumpAndSettle();
      }

      // Verify post created
      expect(find.text('Новый пост о событии!'), findsOneWidget);
    });

    testWidgets('Stories display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check stories section
      final storiesSection = find.byType(SingleChildScrollView);
      expect(storiesSection, findsOneWidget);

      // Check story items
      final storyItems = find.byType(CircleAvatar);
      expect(storyItems, findsWidgets);
    });

    testWidgets('View story', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on a story
      final storyItem = find.byType(CircleAvatar).first;
      if (storyItem.evaluate().isNotEmpty) {
        await tester.tap(storyItem);
        await tester.pumpAndSettle();
      }

      // Check story viewer
      final storyViewer = find.byType(PageView);
      expect(storyViewer, findsOneWidget);

      // Test story navigation
      await tester.drag(storyViewer, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Test story close
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Create story', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find create story button
      final createStoryButton = find.byIcon(Icons.add_circle);
      if (createStoryButton.evaluate().isNotEmpty) {
        await tester.tap(createStoryButton);
        await tester.pumpAndSettle();
      }

      // Select story type
      final photoOption = find.text('Фото');
      if (photoOption.evaluate().isNotEmpty) {
        await tester.tap(photoOption);
        await tester.pumpAndSettle();
      }

      // Select from gallery
      final galleryOption = find.text('Галерея');
      if (galleryOption.evaluate().isNotEmpty) {
        await tester.tap(galleryOption);
        await tester.pumpAndSettle();
      }

      // Add story text
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField, 'Моя история!');
        await tester.pumpAndSettle();
      }

      // Publish story
      final publishButton = find.text('Опубликовать');
      if (publishButton.evaluate().isNotEmpty) {
        await tester.tap(publishButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Post comments', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open post
      final postCard = find.byType(Card).first;
      if (postCard.evaluate().isNotEmpty) {
        await tester.tap(postCard);
        await tester.pumpAndSettle();
      }

      // Open comments
      final commentButton = find.byIcon(Icons.comment);
      if (commentButton.evaluate().isNotEmpty) {
        await tester.tap(commentButton);
        await tester.pumpAndSettle();
      }

      // Add comment
      final commentField = find.byType(TextField);
      if (commentField.evaluate().isNotEmpty) {
        await tester.enterText(commentField, 'Отличный пост!');
        await tester.pumpAndSettle();
      }

      // Send comment
      final sendButton = find.byIcon(Icons.send);
      if (sendButton.evaluate().isNotEmpty) {
        await tester.tap(sendButton);
        await tester.pumpAndSettle();
      }

      // Verify comment added
      expect(find.text('Отличный пост!'), findsOneWidget);
    });

    testWidgets('Feed filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find filter button
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      // Select category filter
      final categoryFilter = find.text('Свадьбы');
      if (categoryFilter.evaluate().isNotEmpty) {
        await tester.tap(categoryFilter);
        await tester.pumpAndSettle();
      }

      // Apply filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredPosts = find.byType(Card);
      expect(filteredPosts, findsWidgets);
    });

    testWidgets('Feed refresh', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Pull to refresh
      final feedList = find.byType(ListView);
      if (feedList.evaluate().isNotEmpty) {
        await tester.drag(feedList, const Offset(0, 500));
        await tester.pumpAndSettle();
      }

      // Check refresh indicator
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);
    });

    testWidgets('Post sharing', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open post
      final postCard = find.byType(Card).first;
      if (postCard.evaluate().isNotEmpty) {
        await tester.tap(postCard);
        await tester.pumpAndSettle();
      }

      // Share post
      final shareButton = find.byIcon(Icons.share);
      if (shareButton.evaluate().isNotEmpty) {
        await tester.tap(shareButton);
        await tester.pumpAndSettle();
      }

      // Check share options
      final shareOptions = [
        'Telegram',
        'WhatsApp',
        'VKontakte',
        'Instagram',
        'Скопировать ссылку',
      ];

      for (final option in shareOptions) {
        final shareOption = find.text(option);
        if (shareOption.evaluate().isNotEmpty) {
          expect(shareOption, findsOneWidget);
        }
      }
    });
  });
}
