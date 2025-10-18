import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import '../widgets/modern_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'bookings_screen_full.dart';
import 'package:flutter/foundation.dart';
import 'chat_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'customer_profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'enhanced_feed_screen.dart';
import 'package:flutter/foundation.dart';
import 'enhanced_ideas_screen.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'package:flutter/foundation.dart';

/// Р“Р»Р°РІРЅС‹Р№ СЌРєСЂР°РЅ СЃ РЅР°РІРёРіР°С†РёРµР№
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
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
      label: 'Р“Р»Р°РІРЅР°СЏ',
      screen: HomeScreen(),
    ),
    const NavigationItem(
      icon: Icons.newspaper_outlined,
      activeIcon: Icons.newspaper,
      label: 'Р›РµРЅС‚Р°',
      screen: EnhancedFeedScreen(),
    ),
    const NavigationItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Р—Р°СЏРІРєРё',
      screen: BookingsScreenFull(),
    ),
    const NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Р§Р°С‚С‹',
      screen: ChatListScreen(),
    ),
    const NavigationItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'РРґРµРё',
      screen: EnhancedIdeasScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('рџ•ђ [${DateTime.now()}] MainNavigationScreen.initState() called');
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

    try {
      setState(() {
        _currentIndex = index;
      });
    } catch (e) {
      debugPrint('Ошибка переключения вкладки: $e');
      // Fallback: устанавливаем безопасное состояние
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° РєРЅРѕРїРєРё "РќР°Р·Р°Рґ" СЃ РїСЂР°РІРёР»СЊРЅРѕР№ Р»РѕРіРёРєРѕР№
  Future<void> _handleBackPress(BuildContext context) async {
    // Р•СЃР»Рё РЅРµ РЅР° РіР»Р°РІРЅРѕР№ РІРєР»Р°РґРєРµ (РёРЅРґРµРєСЃ 0), РїРµСЂРµС…РѕРґРёРј РЅР° РіР»Р°РІРЅСѓСЋ
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // Р•СЃР»Рё РЅР° РіР»Р°РІРЅРѕР№ РІРєР»Р°РґРєРµ, РёСЃРїРѕР»СЊР·СѓРµРј "РґРІРѕР№РЅРѕРµ РЅР°Р¶Р°С‚РёРµ РґР»СЏ РІС‹С…РѕРґР°"
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('РќР°Р¶РјРёС‚Рµ В«РќР°Р·Р°РґВ» РµС‰С‘ СЂР°Р·, С‡С‚РѕР±С‹ РІС‹Р№С‚Рё'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Р’С‚РѕСЂРѕРµ РЅР°Р¶Р°С‚РёРµ - РІС‹С…РѕРґРёРј РёР· РїСЂРёР»РѕР¶РµРЅРёСЏ
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('рџ•ђ [${DateTime.now()}] MainNavigationScreen.build() called, currentIndex: $_currentIndex');
    return PopScope(
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
  }

  Widget? _buildFAB() {
    switch (_currentIndex) {
      case 0: // Р“Р»Р°РІРЅР°СЏ - СѓР±РёСЂР°РµРј FAB, С‚Р°Рє РєР°Рє РїРѕРёСЃРє РІСЃС‚СЂРѕРµРЅ
        return null;
      case 1: // Р›РµРЅС‚Р°
        return ModernFAB(
          tooltip: 'РЎРѕР·РґР°С‚СЊ РїРѕСЃС‚',
          onPressed: () {
            Navigator.pushNamed(context, '/create-post');
          },
        );
      case 2: // Р—Р°СЏРІРєРё
        return ModernFAB(
          icon: Icons.add_task,
          tooltip: 'РЎРѕР·РґР°С‚СЊ Р·Р°СЏРІРєСѓ',
          onPressed: () {
            // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ СЃРѕР·РґР°РЅРёРµ Р·Р°СЏРІРєРё
          },
        );
      case 3: // Р§Р°С‚С‹
        return ModernFAB(
          icon: Icons.chat,
          tooltip: 'РќРѕРІС‹Р№ С‡Р°С‚',
          onPressed: () {
            // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РЅРѕРІС‹Р№ С‡Р°С‚
          },
        );
      case 4: // РРґРµРё
        return ModernFAB(
          tooltip: 'Р”РѕР±Р°РІРёС‚СЊ РёРґРµСЋ',
          onPressed: () {
            Navigator.pushNamed(context, '/add-idea');
          },
        );
      default:
        return ModernFAB(
          tooltip: 'Р”РµР№СЃС‚РІРёРµ',
          onPressed: () {
            // TODO: Р РµР°Р»РёР·РѕРІР°С‚СЊ РґРµР№СЃС‚РІРёРµ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
          },
        );
    }
  }
}

/// РњРѕРґРµР»СЊ СЌР»РµРјРµРЅС‚Р° РЅР°РІРёРіР°С†РёРё
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

/// Р—Р°РіР»СѓС€РєРё РґР»СЏ СЌРєСЂР°РЅРѕРІ

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('РџРѕРёСЃРє'),
          automaticallyImplyLeading: false, // РќРµ РїРѕРєР°Р·С‹РІР°РµРј СЃС‚СЂРµР»РєСѓ РІ С‚Р°Р±Р°С…
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text(
                'РџРѕРёСЃРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ Рё СѓСЃР»СѓРі',
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
    // РџРѕР»СѓС‡Р°РµРј С‚РµРєСѓС‰РµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ РЅРµ Р°РІС‚РѕСЂРёР·РѕРІР°РЅ'),
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
          child: Text('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РїСЂРѕС„РёР»СЏ: $error'),
        ),
      ),
    );
  }
}

