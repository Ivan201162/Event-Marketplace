import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/user_role_provider.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/my_events_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/booking_requests_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    final List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const MyEventsScreen(),
      const ChatsScreen(),
      // роль влияет на 5-ю вкладку
      userRole == UserRole.customer
          ? const MyBookingsScreen()
          : const BookingRequestsScreen(),
      const ProfileScreen(),
    ];

    return MaterialApp(
      title: 'Event Marketplace',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Главная"),
            const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Поиск"),
            const BottomNavigationBarItem(icon: Icon(Icons.event), label: "Мероприятия"),
            const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Чаты"),
            BottomNavigationBarItem(
              icon: Icon(userRole == UserRole.customer ? Icons.book_online : Icons.assignment),
              label: userRole == UserRole.customer ? "Мои заявки" : "Заявки",
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),
          ],
        ),
      ),
    );
  }
}