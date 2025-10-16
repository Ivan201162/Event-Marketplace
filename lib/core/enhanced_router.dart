import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_screen.dart';
import '../screens/enhanced_settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/specialists_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/transliterate_demo_screen.dart';
import '../screens/social_home_screen.dart';
import '../screens/social_profile_screen.dart';
import '../screens/social_chat_screen.dart';
import '../screens/social_chats_list_screen.dart';
import '../screens/social_followers_screen.dart';
import '../screens/social_following_screen.dart';
import '../screens/create_idea_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/enhanced_social_home_screen.dart';
import '../screens/ideas_feed_screen.dart';
import '../screens/monetization/monetization_hub_screen.dart';
import '../screens/monetization/subscription_plans_screen.dart';
import '../screens/monetization/promotion_packages_screen.dart';
import '../screens/monetization/advertisement_campaigns_screen.dart';
import '../screens/monetization/payment_screen.dart';
import '../screens/monetization/my_subscriptions_screen.dart';
import '../screens/monetization/my_promotions_screen.dart';
import '../screens/monetization/my_advertisements_screen.dart';
import '../screens/monetization/create_advertisement_screen.dart';
import '../models/transaction.dart';
import '../models/advertisement.dart';
import '../screens/chats_list_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/create_request_screen.dart';
import '../screens/profile_edit_screen.dart';

/// Провайдер роутера приложения
final routerProvider = Provider<GoRouter>((ref) => GoRouter(
    initialLocation: '/',
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth screen
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Главная навигация
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainNavigationScreen(),
        routes: [
          // Главная
          GoRoute(
            path: 'home',
            name: 'home',
            builder: (context, state) => const EnhancedSocialHomeScreen(),
          ),

          // Лента
          GoRoute(
            path: 'feed',
            name: 'feed',
            builder: (context, state) => const IdeasFeedScreen(),
          ),

          // Идеи
          GoRoute(
            path: 'ideas',
            name: 'ideas',
            builder: (context, state) => const IdeasFeedScreen(),
          ),

          // Настройки
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const EnhancedSettingsScreen(),
          ),
        ],
      ),

      // Прямые маршруты для быстрого доступа
      GoRoute(
        path: '/home',
        name: 'home-direct',
        builder: (context, state) => const EnhancedSocialHomeScreen(),
      ),

      GoRoute(
        path: '/feed',
        name: 'feed-direct',
        builder: (context, state) => const IdeasFeedScreen(),
      ),

      GoRoute(
        path: '/ideas',
        name: 'ideas-direct',
        builder: (context, state) => const IdeasFeedScreen(),
      ),

      GoRoute(
        path: '/settings',
        name: 'settings-direct',
        builder: (context, state) => const EnhancedSettingsScreen(),
      ),

      // Новые маршруты
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatsListScreen(),
      ),

      GoRoute(
        path: '/chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatScreen(chatId: chatId);
        },
      ),

      GoRoute(
        path: '/ideas/create',
        name: 'create-idea',
        builder: (context, state) => const CreateIdeaScreen(),
      ),

      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const RequestsScreen(),
      ),

      GoRoute(
        path: '/requests/create',
        name: 'create-request',
        builder: (context, state) => const CreateRequestScreen(),
      ),

      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const ProfileEditScreen(),
      ),

      // Маршруты монетизации
      GoRoute(
        path: '/monetization',
        name: 'monetization',
        builder: (context, state) => const MonetizationHubScreen(),
      ),
      GoRoute(
        path: '/monetization/subscriptions',
        name: 'subscriptions',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/monetization/promotions',
        name: 'promotions',
        builder: (context, state) => const PromotionPackagesScreen(),
      ),
      GoRoute(
        path: '/monetization/advertisements',
        name: 'advertisements',
        builder: (context, state) => const AdvertisementCampaignsScreen(),
      ),
      GoRoute(
        path: '/monetization/payment',
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentScreen(
            type: extra?['type'] ?? PaymentType.subscription,
          );
        },
      ),
      GoRoute(
        path: '/monetization/my-subscriptions',
        name: 'my-subscriptions',
        builder: (context, state) => const MySubscriptionsScreen(),
      ),
      GoRoute(
        path: '/monetization/my-promotions',
        name: 'my-promotions',
        builder: (context, state) => const MyPromotionsScreen(),
      ),
      GoRoute(
        path: '/monetization/my-advertisements',
        name: 'my-advertisements',
        builder: (context, state) => const MyAdvertisementsScreen(),
      ),
      GoRoute(
        path: '/monetization/create-advertisement',
        name: 'create-advertisement',
        builder: (context, state) {
          final type = state.extra as AdType? ?? AdType.banner;
          return CreateAdvertisementScreen();
        },
      ),

      // Профиль
      GoRoute(
        path: '/profile/me',
        name: 'profile-me',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/profile/:userId',
        name: 'profile-user',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),

      // Уведомления
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Поиск
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchScreen(query: query);
        },
      ),

      // Специалисты
      GoRoute(
        path: '/specialists',
        name: 'specialists',
        builder: (context, state) => const SpecialistsScreen(),
      ),

      GoRoute(
        path: '/specialist/:id',
        name: 'specialist-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SpecialistDetailScreen(specialistId: id);
        },
      ),

      // Заявки
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const RequestsScreen(),
      ),

      GoRoute(
        path: '/requests/create',
        name: 'requests-create',
        builder: (context, state) => const CreateRequestScreen(),
      ),

      // Чаты
      GoRoute(
        path: '/chats',
        name: 'chats',
        builder: (context, state) => const ChatsScreen(),
      ),

      GoRoute(
        path: '/chat/:chatId',
        name: 'chat-detail',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatDetailScreen(chatId: chatId);
        },
      ),

      // Идеи
      GoRoute(
        path: '/idea/:id',
        name: 'idea-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return IdeaDetailScreen(ideaId: id);
        },
      ),

      GoRoute(
        path: '/ideas/create',
        name: 'ideas-create',
        builder: (context, state) => const CreateIdeaScreen(),
      ),

      // Помощь и поддержка
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),

      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),

      GoRoute(
        path: '/bug-report',
        name: 'bug-report',
        builder: (context, state) => const BugReportScreen(),
      ),

      // Демо транслитерации
      GoRoute(
        path: '/transliterate-demo',
        name: 'transliterate-demo',
        builder: (context, state) => const TransliterateDemoScreen(),
      ),

      // Социальные маршруты
      GoRoute(
        path: '/social-home',
        name: 'social-home',
        builder: (context, state) => const SocialHomeScreen(),
      ),

      GoRoute(
        path: '/profile/:username',
        name: 'social-profile',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return SocialProfileScreen(username: username);
        },
      ),

      GoRoute(
        path: '/chat/:chatId',
        name: 'social-chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return SocialChatScreen(chatId: chatId);
        },
      ),

      GoRoute(
        path: '/chats',
        name: 'social-chats-list',
        builder: (context, state) => const SocialChatsListScreen(),
      ),

      GoRoute(
        path: '/profile/:username/followers',
        name: 'social-followers',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return SocialFollowersScreen(username: username);
        },
      ),

      GoRoute(
        path: '/profile/:username/following',
        name: 'social-following',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return SocialFollowingScreen(username: username);
        },
      ),

      // Создание идеи
      GoRoute(
        path: '/create-idea',
        name: 'create-idea',
        builder: (context, state) => const CreateIdeaScreen(),
      ),

      // Редактирование профиля
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  ),);

/// Главный экран навигации
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SocialHomeScreen(),
    const FeedScreen(),
    const RequestsScreen(),
    const ChatsScreen(),
    const IdeasScreen(),
    const MonetizationHubScreen(), // Добавляем экран монетизации
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => context.push('/profile/me'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Лента',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Идеи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Монетизация',
          ),
        ],
      ),
    );
}

// Заглушки для экранов, которые будут реализованы позже

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => context.push('/profile/me'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const Center(child: Text('Уведомления')),
    );
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Поиск')),
      body: Center(child: Text('Поиск: $query')),
    );
}


class SpecialistDetailScreen extends StatelessWidget {
  const SpecialistDetailScreen({super.key, required this.specialistId});
  final String specialistId;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Специалист')),
      body: Center(child: Text('Специалист: $specialistId')),
    );
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(child: Text('Заявки')),
    );
}

class CreateRequestScreen extends StatelessWidget {
  const CreateRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Создать заявку')),
      body: const Center(child: Text('Создать заявку')),
    );
}

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(child: Text('Чаты')),
    );
}

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key, required this.chatId});
  final String chatId;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Чат')),
      body: Center(child: Text('Чат: $chatId')),
    );
}

class IdeaDetailScreen extends StatelessWidget {
  const IdeaDetailScreen({super.key, required this.ideaId});
  final String ideaId;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Идея')),
      body: Center(child: Text('Идея: $ideaId')),
    );
}

class CreateIdeaScreen extends StatelessWidget {
  const CreateIdeaScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Создать идею')),
      body: const Center(child: Text('Создать идею')),
    );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Справка')),
      body: const Center(child: Text('Справка')),
    );
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Поддержка')),
      body: const Center(child: Text('Поддержка')),
    );
}

class BugReportScreen extends StatelessWidget {
  const BugReportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Сообщить об ошибке')),
      body: const Center(child: Text('Сообщить об ошибке')),
    );
}

// Основные экраны приложения
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Главный экран', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Поиск специалистов и лучшие предложения'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: null, // TODO: Добавить навигацию к поиску
              child: Text('Найти специалистов'),
            ),
          ],
        ),
      ),
    );
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dynamic_feed, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Лента', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Посты, фото и видео от специалистов'),
          ],
        ),
      ),
    );
}

class IdeasScreen extends StatelessWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Идеи', style: TextStyle(fontSize: 24)),
            SizedBox(height: 8),
            Text('Фото и видео идеи для мероприятий'),
          ],
        ),
      ),
    );
}


