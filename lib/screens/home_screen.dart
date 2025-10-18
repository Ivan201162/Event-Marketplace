import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import '../providers/local_data_providers.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('рџ•ђ [${DateTime.now()}] HomeScreen.initState() called');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('рџ•ђ [${DateTime.now()}] HomeScreen.build() called');
    
    try {
      final currentUserAsync = ref.watch(currentUserProvider);
      final localDataInitialized = ref.watch(localDataInitializedProvider);

      return localDataInitialized.when(
        data: (initialized) {
          if (!initialized) {
            return _buildLoadingState();
          }

          return currentUserAsync.when(
            data: _buildHomeContent,
            loading: _buildLoadingState,
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
        loading: _buildLoadingState,
        error: (error, stack) => _buildErrorState(error.toString()),
      );
    } catch (e, stack) {
      debugPrint('рџљЁ [${DateTime.now()}] HomeScreen error: $e');
      debugPrint('Stack: $stack');
      
      // Fallback UI РїСЂРё РѕС€РёР±РєРµ
      return _buildFallbackHomeScreen();
    }
  }

  /// РџСЂРѕСЃС‚РѕР№ fallback СЌРєСЂР°РЅ РїСЂРё РѕС€РёР±РєР°С…
  Widget _buildFallbackHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('рџЏ  Р“Р»Р°РІРЅР°СЏ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'рџЏ  Р“Р»Р°РІРЅС‹Р№ СЌРєСЂР°РЅ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'РџСЂРёР»РѕР¶РµРЅРёРµ СЂР°Р±РѕС‚Р°РµС‚!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                debugPrint('рџ”„ [${DateTime.now()}] Retry HomeScreen');
                setState(() {}); // РџРµСЂРµР·Р°РіСЂСѓР¶Р°РµРј СЌРєСЂР°РЅ
              },
              child: const Text('РћР±РЅРѕРІРёС‚СЊ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(user) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserProfileCard(user),
            const SizedBox(height: 16),
            _buildSearchSection(),
            const SizedBox(height: 20),
            _buildCategoriesSection(),
            const SizedBox(height: 20),
            _buildQuickActionsSection(),
          ],
        ),
      );

  Widget _buildUserProfileCard(user) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: user?.photoUrl?.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Р’РѕР№РґРёС‚Рµ РІ Р°РєРєР°СѓРЅС‚',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user?.city?.trim().isNotEmpty == true ? user!.city! : 'Р“РѕСЂРѕРґ РЅРµ СѓРєР°Р·Р°РЅ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/profile'),
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchSection() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'РќР°Р№С‚Рё СЃРїРµС†РёР°Р»РёСЃС‚Р°',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'РџРѕРёСЃРє РїРѕ РёРјРµРЅРё, РєР°С‚РµРіРѕСЂРёРё, РіРѕСЂРѕРґСѓ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  context.push('/search?q=${Uri.encodeComponent(query)}');
                }
              },
            ),
          ],
        ),
      );

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Р’РµРґСѓС‰РёРµ', 'icon': 'рџЋ¤', 'color': Colors.blue},
      {'name': 'DJ', 'icon': 'рџЋµ', 'color': Colors.purple},
      {'name': 'Р¤РѕС‚РѕРіСЂР°С„С‹', 'icon': 'рџ“ё', 'color': Colors.orange},
      {'name': 'Р’РёРґРµРѕРіСЂР°С„С‹', 'icon': 'рџЋ¬', 'color': Colors.red},
      {'name': 'Р”РµРєРѕСЂР°С‚РѕСЂС‹', 'icon': 'рџЋЁ', 'color': Colors.green},
      {'name': 'РђРЅРёРјР°С‚РѕСЂС‹', 'icon': 'рџЋ­', 'color': Colors.teal},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'РљР°С‚РµРіРѕСЂРёРё',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    context.push(
                      '/search?category=${Uri.encodeComponent(category['name']! as String)}',
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: (category['color']! as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (category['color']! as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['icon']! as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['name']! as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Р‘С‹СЃС‚СЂС‹Рµ РґРµР№СЃС‚РІРёСЏ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    title: 'РЎРѕР·РґР°С‚СЊ Р·Р°СЏРІРєСѓ',
                    icon: Icons.add_circle_outline,
                    color: Colors.blue,
                    onTap: () => context.push('/create-request'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    title: 'РњРѕРё Р·Р°СЏРІРєРё',
                    icon: Icons.assignment,
                    color: Colors.green,
                    onTap: () => context.push('/requests'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildLoadingState() => const Center(
        child: CircularProgressIndicator(),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(currentUserProvider);
              },
              child: const Text('РџРѕРІС‚РѕСЂРёС‚СЊ'),
            ),
          ],
        ),
      );
}

