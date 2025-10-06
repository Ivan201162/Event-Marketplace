import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/modern_navigation_bar.dart';
import 'bookings_screen_full.dart';
import 'chat_list_screen.dart';
import 'customer_profile_screen.dart';
import 'feed_screen.dart';
import 'home_screen.dart';

/// Главный экран с навигацией
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime? _lastBackPressTime;

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Главная',
      screen: HomeScreen(),
    ),
    const NavigationItem(
      icon: Icons.newspaper_outlined,
      activeIcon: Icons.newspaper,
      label: 'Лента',
      screen: FeedScreen(),
    ),
    const NavigationItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Заявки',
      screen: BookingsScreenFull(),
    ),
    const NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Чаты',
      screen: ChatListScreen(),
    ),
    const NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Профиль',
      screen: ProfileScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
  }

  /// Обработка кнопки "Назад" с правильной логикой
  Future<void> _handleBackPress(BuildContext context) async {
    // Если не на главной вкладке (индекс 0), переходим на главную
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // Если на главной вкладке, используем "двойное нажатие для выхода"
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нажмите «Назад» ещё раз, чтобы выйти'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Второе нажатие - выходим из приложения
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            await _handleBackPress(context);
          }
        },
        child: ModernScaffold(
          currentIndex: _currentIndex,
          onNavigationTap: _onNavigationTap,
          fab: _buildFAB(),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: IndexedStack(
              index: _currentIndex,
              children: _navigationItems.map((item) => item.screen).toList(),
            ),
          ),
        ),
      );

  Widget? _buildFAB() {
    switch (_currentIndex) {
      case 0: // Главная - убираем FAB, так как поиск встроен
        return null;
      case 1: // Лента
        return ModernFAB(
          tooltip: 'Создать пост',
          onPressed: () {
            Navigator.pushNamed(context, '/create-post');
          },
        );
      case 2: // Заявки
        return ModernFAB(
          icon: Icons.add_task,
          tooltip: 'Создать заявку',
          onPressed: () {
            // TODO: Реализовать создание заявки
          },
        );
      case 3: // Чаты
        return ModernFAB(
          icon: Icons.chat,
          tooltip: 'Новый чат',
          onPressed: () {
            // TODO: Реализовать новый чат
          },
        );
      case 4: // Профиль
        return ModernFAB(
          icon: Icons.edit,
          tooltip: 'Редактировать профиль',
          onPressed: () {
            // TODO: Реализовать редактирование профиля
          },
        );
      default:
        return ModernFAB(
          tooltip: 'Действие',
          onPressed: () {
            // TODO: Реализовать действие по умолчанию
          },
        );
    }
  }
}

/// Модель элемента навигации
class NavigationItem {
  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
}

/// Заглушки для экранов

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поиск'),
          automaticallyImplyLeading: false, // Не показываем стрелку в табах
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text(
                'Поиск специалистов и услуг',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const BookingsScreenFull();
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем текущего пользователя
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Пользователь не авторизован'),
            ),
          );
        }

        return CustomerProfileScreen(
          userId: user.id,
          isOwnProfile: true,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Ошибка загрузки профиля: $error'),
        ),
      ),
    );
  }
}
