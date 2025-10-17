import 'dart:ui';

import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка обработки ошибок
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("🔥 Flutter error: ${details.exception}");
    debugPrint("Stack: ${details.stack}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("🔥 Uncaught error: $error");
    debugPrint("Stack: $stack");
    return true;
  };

  debugPrint('🚀 Starting EventMarketplaceApp...');
  runApp(const EventMarketplaceApp());
}

class EventMarketplaceApp extends StatelessWidget {
  const EventMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Marketplace',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const FeedTab(),
    const BookingsTab(),
    const ChatsTab(),
    const IdeasTab(),
    const MonetizationTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
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
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '🏠 Главная',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Добро пожаловать в Event Marketplace!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '📰 Социальная лента',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Посты, фото, видео, рилсы',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '📋 Заявки',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Мои заявки и заявки мне',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '💬 Чаты',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Общение с клиентами и специалистами',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IdeasTab extends StatelessWidget {
  const IdeasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Идеи'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '💡 Идеи',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Креативные идеи для мероприятий',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonetizationTab extends StatelessWidget {
  const MonetizationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Монетизация'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              '💰 Монетизация',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Подписки и реклама',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
