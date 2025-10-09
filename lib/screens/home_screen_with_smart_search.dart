import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smart_specialist.dart';
import '../services/ai_assistant_service.dart';
import '../services/smart_search_service.dart';
import '../services/smart_specialist_data_generator.dart';
import '../widgets/specialist_card.dart';
import 'smart_search_screen.dart';

/// Главный экран с интеграцией умного поиска
class HomeScreenWithSmartSearch extends ConsumerStatefulWidget {
  const HomeScreenWithSmartSearch({super.key});

  @override
  ConsumerState<HomeScreenWithSmartSearch> createState() => _HomeScreenWithSmartSearchState();
}

class _HomeScreenWithSmartSearchState extends ConsumerState<HomeScreenWithSmartSearch> {
  final SmartSearchService _smartSearchService = SmartSearchService();
  final AIAssistantService _aiAssistantService = AIAssistantService();
  final SmartSpecialistDataGenerator _dataGenerator = SmartSpecialistDataGenerator();
  
  List<SmartSpecialist> _recommendations = [];
  List<SmartSpecialist> _popularSpecialists = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Загрузить данные
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем популярных специалистов
      final popularSpecialists = await _smartSearchService.getPopularSpecialists(limit: 6);
      
      // Загружаем персональные рекомендации если есть userId
      var recommendations = <SmartSpecialist>[];
      if (_currentUserId != null) {
        recommendations = await _smartSearchService.getPersonalRecommendations(
          _currentUserId!,
          limit: 6,
        );
      }
      
      setState(() {
        _popularSpecialists = popularSpecialists;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    }
  }

  /// Открыть умный поиск
  void _openSmartSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SmartSearchScreen(),
      ),
    );
  }

  /// Открыть AI-помощника
  Future<void> _openAIAssistant() async {
    final conversation = await _aiAssistantService.startConversation(userId: _currentUserId);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AIAssistantDialog(
          conversation: conversation,
          onClose: () {},
        ),
      );
    }
  }

  /// Сгенерировать тестовые данные
  Future<void> _generateTestData() async {
    setState(() => _isLoading = true);
    
    try {
      await _dataGenerator.generateTestSpecialists();
      await _loadData();
      _showSuccessSnackBar('Тестовые данные успешно сгенерированы!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка генерации данных: $e');
    }
  }

  /// Показать ошибку
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Показать успех
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Event Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: _openAIAssistant,
            tooltip: 'AI-помощник',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'generate_data':
                  _generateTestData();
                  break;
                case 'refresh':
                  _loadData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate_data',
                child: Text('Сгенерировать тестовые данные'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Обновить'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Приветствие
                    const Text(
                      'Добро пожаловать!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Найдите идеального специалиста для вашего мероприятия',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопки быстрого доступа
                    _buildQuickAccessButtons(),
                    const SizedBox(height: 24),
                    
                    // Персональные рекомендации
                    if (_recommendations.isNotEmpty) ...[
                      _buildSectionHeader(
                        '🔮 Вам подойдут эти специалисты',
                        'На основе ваших предпочтений',
                      ),
                      const SizedBox(height: 16),
                      _buildSpecialistsList(_recommendations, showCompatibility: true),
                      const SizedBox(height: 32),
                    ],
                    
                    // Популярные специалисты
                    _buildSectionHeader(
                      '⭐ Популярные специалисты',
                      'Высокий рейтинг и много отзывов',
                    ),
                    const SizedBox(height: 16),
                    _buildSpecialistsList(_popularSpecialists),
                    const SizedBox(height: 32),
                    
                    // Кнопка "Показать всех"
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _openSmartSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('Найти специалиста'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAIAssistant,
        tooltip: 'AI-помощник',
        child: const Icon(Icons.smart_toy),
      ),
    );

  /// Построить кнопки быстрого доступа
  Widget _buildQuickAccessButtons() => Row(
      children: [
        Expanded(
          child: _buildQuickAccessButton(
            icon: Icons.search,
            title: 'Умный поиск',
            subtitle: 'Найти специалиста',
            onTap: _openSmartSearch,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAccessButton(
            icon: Icons.smart_toy,
            title: 'AI-помощник',
            subtitle: 'Подобрать за вас',
            onTap: _openAIAssistant,
            color: Colors.purple,
          ),
        ),
      ],
    );

  /// Построить кнопку быстрого доступа
  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  /// Построить заголовок секции
  Widget _buildSectionHeader(String title, String subtitle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );

  /// Построить список специалистов
  Widget _buildSpecialistsList(List<SmartSpecialist> specialists, {bool showCompatibility = false}) {
    if (specialists.isEmpty) {
      return const Center(
        child: Text(
          'Специалисты не найдены',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            child: SpecialistCard(
              specialist: specialist,
              showCompatibility: showCompatibility,
              onTap: () => _onSpecialistTap(specialist),
            ),
          );
        },
      ),
    );
  }

  /// Обработка нажатия на специалиста
  void _onSpecialistTap(SmartSpecialist specialist) {
    // Записываем взаимодействие
    if (_currentUserId != null) {
      _smartSearchService.recordUserInteraction(
        userId: _currentUserId!,
        specialistId: specialist.id,
        action: 'view',
      );
    }
    
    // Переходим к профилю специалиста
    Navigator.pushNamed(
      context,
      '/specialist_profile',
      arguments: specialist.id,
    );
  }
}
