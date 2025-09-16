import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/my_events_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/profile_page.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/booking_requests_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/chat_extended_screen.dart';
import 'screens/chats_demo_screen.dart';
import 'screens/payments_extended_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'widgets/animated_page_transition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Инициализация FCM
  await FCMService().initialize();
  
  // Инициализация сервиса уведомлений
  await NotificationService().initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      title: 'Event Marketplace',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: _buildHome(authState),
      // Локализация
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: ref.watch(localeProvider),
      // Анимации переходов
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return AnimatedPageTransitions.fadeTransition(
              child: _buildHome(authState),
              context: context,
            );
          default:
            return AnimatedPageTransitions.slideLeftTransition(
              child: _buildHome(authState),
              context: context,
            );
        }
      },
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState) {
      case AuthState.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка...'),
              ],
            ),
          ),
        );
      case AuthState.authenticated:
        return const MainApp();
      case AuthState.unauthenticated:
      case AuthState.error:
        return const AuthScreen();
    }
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(currentUserRoleProvider);
    final isSpecialist = ref.watch(isSpecialistProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const RecommendationsScreen(),
      const MyEventsScreen(),
      const ChatsDemoScreen(),
      // роль влияет на 6-ю вкладку
      isSpecialist
          ? const BookingRequestsScreen()
          : const MyBookingsScreen(),
      const ProfilePage(),
      // Добавляем админ-панель только в debug режиме
      if (kDebugMode) const AdminPanelScreen(),
      // Добавляем экран отладки только в debug режиме
      if (kDebugMode) const DebugScreen(),
    ];

    final bottomNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Главная"),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Поиск"),
      const BottomNavigationBarItem(icon: Icon(Icons.recommend), label: "Рекомендации"),
      const BottomNavigationBarItem(icon: Icon(Icons.event), label: "Мероприятия"),
      const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Чаты"),
      BottomNavigationBarItem(
        icon: Icon(isSpecialist ? Icons.assignment : Icons.book_online),
        label: isSpecialist ? "Заявки" : "Мои заявки",
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
      // Добавляем админ-панель только в debug режиме
      if (kDebugMode) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Админ"),
      // Добавляем вкладку отладки только в debug режиме
      if (kDebugMode) const BottomNavigationBarItem(icon: Icon(Icons.bug_report), label: "Отладка"),
    ];

    if (isMobile) {
      // Мобильная навигация с BottomNavigationBar и PageView
      return Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: pages.map((page) => AnimatedAppearance(
            child: page,
            delay: const Duration(milliseconds: 100),
          )).toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          items: bottomNavItems,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        ),
      );
    } else {
      // Десктопная навигация с NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: bottomNavItems.map((item) => NavigationRailDestination(
                icon: item.icon,
                label: Text(item.label!),
              )).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }
  }
}