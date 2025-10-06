import 'package:flutter/material.dart';
import '../services/news_feed_service.dart';
import '../widgets/news_feed_widget.dart';
import '../widgets/specialist_subscription_widget.dart';

/// Тестовый экран для проверки функциональности ленты новостей
class NewsFeedTestScreen extends StatefulWidget {
  const NewsFeedTestScreen({super.key});

  @override
  State<NewsFeedTestScreen> createState() => _NewsFeedTestScreenState();
}

class _NewsFeedTestScreenState extends State<NewsFeedTestScreen>
    with TickerProviderStateMixin {
  final NewsFeedService _newsService = NewsFeedService();

  final String _testUserId = 'test_user_123';
  final String _testSpecialistId = 'test_specialist_456';

  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Тест ленты новостей'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: TabController(
              length: 3,
              vsync: this,
              initialIndex: _selectedTabIndex,
            ),
            onTap: (index) => setState(() => _selectedTabIndex = index),
            tabs: const [
              Tab(icon: Icon(Icons.newspaper), text: 'Лента'),
              Tab(icon: Icon(Icons.subscriptions), text: 'Подписки'),
              Tab(icon: Icon(Icons.add), text: 'Создать'),
            ],
          ),
        ),
        body: TabBarView(
          controller: TabController(
            length: 3,
            vsync: this,
            initialIndex: _selectedTabIndex,
          ),
          children: [
            _buildNewsFeedTab(),
            _buildSubscriptionsTab(),
            _buildCreateNewsTab(),
          ],
        ),
      );

  Widget _buildNewsFeedTab() => Column(
        children: [
          _buildTestInfo(),
          Expanded(
            child: NewsFeedWidget(
              userId: _testUserId,
              onNewsItemTap: _showNewsItemDetails,
              onAuthorTap: _showAuthorProfile,
            ),
          ),
        ],
      );

  Widget _buildSubscriptionsTab() => SingleChildScrollView(
        child: Column(
          children: [
            _buildTestInfo(),
            SpecialistSubscriptionWidget(
              userId: _testUserId,
              onSubscriptionChanged: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Подписки обновлены'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildCreateNewsTab() => SingleChildScrollView(
        child: Column(
          children: [
            _buildTestInfo(),
            _buildCreateNewsForm(),
          ],
        ),
      );

  Widget _buildTestInfo() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Информация о тесте',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('User ID: $_testUserId'),
            Text('Specialist ID: $_testSpecialistId'),
            const SizedBox(height: 8),
            const Text(
              'Этот экран позволяет протестировать функциональность ленты новостей, подписок и создания новостей.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildCreateNewsForm() => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Создать новость',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCreateNewsButtons(),
            ],
          ),
        ),
      );

  Widget _buildCreateNewsButtons() => Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createTestNews,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Создать тестовые новости'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createIdeaNews,
              icon: const Icon(Icons.lightbulb),
              label: const Text('Создать идею'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createPromotionNews,
              icon: const Icon(Icons.local_offer),
              label: const Text('Создать акцию'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createStoryNews,
              icon: const Icon(Icons.book),
              label: const Text('Создать историю'),
            ),
          ),
        ],
      );

  // ========== МЕТОДЫ ==========

  void _showNewsItemDetails(NewsItem newsItem) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newsItem.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      newsItem.authorName.isNotEmpty
                          ? newsItem.authorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          newsItem.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          newsItem.formattedDate,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                newsItem.content,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text('${newsItem.likes}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.share, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text('${newsItem.shares}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.visibility, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text('${newsItem.views}'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showAuthorProfile(String authorId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Профиль специалиста'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                authorId.isNotEmpty ? authorId[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Специалист $authorId',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Описание специалиста...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO(developer): Implement subscription
            },
            child: const Text('Подписаться'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestNews() async {
    try {
      await _newsService.createTestNews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовые новости созданы'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания тестовых новостей: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createIdeaNews() async {
    try {
      await _newsService.createNewsItem(
        authorId: _testSpecialistId,
        authorName: 'Тестовый специалист',
        type: NewsType.idea,
        title: 'Новая идея для мероприятий',
        content:
            'Представляю вам новую креативную идею для организации мероприятий. Эта идея поможет сделать ваше событие незабываемым.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Идея создана'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания идеи: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPromotionNews() async {
    try {
      await _newsService.createNewsItem(
        authorId: _testSpecialistId,
        authorName: 'Тестовый специалист',
        type: NewsType.promotion,
        title: 'Специальное предложение',
        content:
            'Скидка 30% на все услуги при заказе до конца месяца. Успейте забронировать!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Акция создана'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания акции: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createStoryNews() async {
    try {
      await _newsService.createNewsItem(
        authorId: _testSpecialistId,
        authorName: 'Тестовый специалист',
        type: NewsType.story,
        title: 'История успеха',
        content:
            'Рассказываю о том, как мы организовали незабываемое мероприятие. Много интересных деталей и секретов успеха.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('История создана'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания истории: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
