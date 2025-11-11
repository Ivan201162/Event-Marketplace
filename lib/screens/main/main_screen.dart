import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';
import '../feed/feed_screen.dart';
import '../requests/requests_screen.dart';
import '../chat/chat_list_screen.dart';
import '../ideas/ideas_screen_simple.dart';
import '../../utils/debug_log.dart';
import 'dart:developer' as developer;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FeedScreen(),
    const RequestsScreen(),
    const ChatListScreen(),
    const IdeasScreenSimple(),
  ];

  final List<String> _screenNames = [
    'Home',
    'Feed',
    'Requests',
    'Chat',
    'Ideas',
  ];

  @override
  void initState() {
    super.initState();
    developer.log('MAIN_SHELL:opened', name: 'MainScreen');
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          developer.log('MAIN_SHELL:tab=${_screenNames[index]}', name: 'MainScreen');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            isActive ? activeIcon : icon,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 24, // iOS/Telegram стиль
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens.map((screen) {
          final index = _screens.indexOf(screen);
          return _ScreenWrapper(
            screenName: _screenNames[index],
            child: screen,
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        height: 56, // Фиксированная высота 56dp
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, Icons.home, 0),
              _buildNavItem(Icons.grid_3x3, Icons.grid_3x3, 1),
              _buildNavItem(Icons.assignment, Icons.assignment, 2),
              _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 3),
              _buildNavItem(Icons.lightbulb_outline, Icons.lightbulb, 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenWrapper extends StatelessWidget {
  final String screenName;
  final Widget child;

  const _ScreenWrapper({required this.screenName, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Row(
            children: [
              Text('SCREEN:$screenName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              _ItemCounter(screenName: screenName),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ItemCounter extends StatelessWidget {
  final String screenName;

  const _ItemCounter({required this.screenName});

  @override
  Widget build(BuildContext context) {
    switch (screenName) {
      case 'Home':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('roles', isNotEqualTo: null)
              .limit(1)
              .snapshots(),
          builder: (ctx, snap) {
            final count = snap.hasData ? snap.data!.docs.length : 0;
            return Text('Items: $count');
          },
        );
      case 'Feed':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .limit(1)
              .snapshots(),
          builder: (ctx, snap) {
            final count = snap.hasData ? snap.data!.docs.length : 0;
            return Text('Items: $count');
          },
        );
      case 'Requests':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .limit(1)
              .snapshots(),
          builder: (ctx, snap) {
            final count = snap.hasData ? snap.data!.docs.length : 0;
            return Text('Items: $count');
          },
        );
      case 'Chat':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .limit(1)
              .snapshots(),
          builder: (ctx, snap) {
            final count = snap.hasData ? snap.data!.docs.length : 0;
            return Text('Items: $count');
          },
        );
      case 'Ideas':
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ideas')
              .limit(1)
              .snapshots(),
          builder: (ctx, snap) {
            final count = snap.hasData ? snap.data!.docs.length : 0;
            return Text('Items: $count');
          },
        );
      default:
        return const Text('Items: 0');
    }
  }
}
