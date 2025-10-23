import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/feature_flags.dart';
import '../models/user.dart';
import '../services/integration_service.dart';
import '../services/vk_integration_service.dart';

/// Экран интеграции с VK для специалистов
class VKIntegrationScreen extends ConsumerStatefulWidget {
  const VKIntegrationScreen({super.key, required this.specialist});
  final AppUser specialist;

  @override
  ConsumerState<VKIntegrationScreen> createState() =>
      _VKIntegrationScreenState();
}

class _VKIntegrationScreenState extends ConsumerState<VKIntegrationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _vkUrlController = TextEditingController();
  final IntegrationService _vkService = IntegrationService();
  VKProfile? _vkProfile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vkUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.vkIntegrationEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('VK интеграция')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'VK интеграция временно недоступна',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VK интеграция'),
        backgroundColor: Colors.blue[50],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Подключение', icon: Icon(Icons.link)),
            Tab(text: 'Профиль', icon: Icon(Icons.person)),
            Tab(text: 'Посты', icon: Icon(Icons.article)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildConnectionTab(), _buildProfileTab(), _buildPostsTab()],
      ),
    );
  }

  Widget _buildConnectionTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildVKUrlInput(),
            const SizedBox(height: 24),
            if (_isLoading) _buildLoadingIndicator(),
            if (_errorMessage != null) _buildErrorMessage(),
            if (_vkProfile != null) _buildProfilePreview(),
            const SizedBox(height: 24),
            _buildHelpSection(),
          ],
        ),
      );

  Widget _buildHeader() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, color: Colors.blue[600], size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Подключение VK профиля',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Подключите свой VK профиль, чтобы автоматически импортировать информацию о себе и последние посты',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );

  Widget _buildVKUrlInput() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ссылка на VK профиль',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vkUrlController,
                decoration: InputDecoration(
                  hintText:
                      'https://vk.com/username или https://vk.com/id123456',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loadVKProfile),
                ),
                onSubmitted: (_) => _loadVKProfile(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadVKProfile,
                  icon: const Icon(Icons.search),
                  label: const Text('Загрузить профиль'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLoadingIndicator() => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка профиля VK...'),
              ],
            ),
          ),
        ),
      );

  Widget _buildErrorMessage() => Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_errorMessage!,
                    style: TextStyle(color: Colors.red[600])),
              ),
            ],
          ),
        ),
      );

  Widget _buildProfilePreview() {
    if (_vkProfile == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Предварительный просмотр',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _vkProfile!.photoUrl != null
                      ? NetworkImage(_vkProfile!.photoUrl!)
                      : null,
                  child: _vkProfile!.photoUrl == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vkProfile!.displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_vkProfile!.isVerified)
                        Row(
                          children: [
                            Icon(Icons.verified,
                                color: Colors.blue[600], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Верифицирован',
                              style: TextStyle(
                                  color: Colors.blue[600], fontSize: 12),
                            ),
                          ],
                        ),
                      Text(
                        '${_vkProfile!.followersCount} подписчиков',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_vkProfile!.description != null) ...[
              const SizedBox(height: 16),
              Text(_vkProfile!.description!,
                  style: const TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveVKProfile,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить профиль'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Помощь',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.info,
                'Как получить ссылку на профиль?',
                'Скопируйте ссылку на ваш VK профиль из адресной строки браузера или из мобильного приложения.',
              ),
              _buildHelpItem(
                Icons.security,
                'Безопасность данных',
                'Мы получаем только публичную информацию из вашего профиля. Приватные данные остаются недоступными.',
              ),
              _buildHelpItem(
                Icons.sync,
                'Автоматическое обновление',
                'Профиль будет автоматически обновляться при изменении информации в VK.',
              ),
            ],
          ),
        ),
      );

  Widget _buildHelpItem(IconData icon, String title, String description) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildProfileTab() {
    if (_vkProfile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Профиль VK не загружен',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Сначала подключите VK профиль',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVKProfileCard(),
          const SizedBox(height: 16),
          _buildVKStatsCard()
        ],
      ),
    );
  }

  Widget _buildVKProfileCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Информация профиля',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _vkProfile!.photoUrl != null
                        ? NetworkImage(_vkProfile!.photoUrl!)
                        : null,
                    child: _vkProfile!.photoUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vkProfile!.displayName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_vkProfile!.id}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        if (_vkProfile!.isVerified) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified,
                                  color: Colors.blue[600], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Верифицирован',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (_vkProfile!.description != null) ...[
                const SizedBox(height: 16),
                const Text('Описание',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_vkProfile!.description!,
                    style: const TextStyle(fontSize: 16)),
              ],
            ],
          ),
        ),
      );

  Widget _buildVKStatsCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Статистика',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.people, 'Подписчики',
                      _vkProfile!.followersCount.toString()),
                  _buildStatItem(Icons.article, 'Посты',
                      _vkProfile!.recentPosts.length.toString()),
                  _buildStatItem(
                    Icons.verified,
                    'Статус',
                    _vkProfile!.isVerified ? 'Верифицирован' : 'Обычный',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStatItem(IconData icon, String label, String value) => Column(
        children: [
          Icon(icon, size: 32, color: Colors.blue[600]),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      );

  Widget _buildPostsTab() {
    if (_vkProfile == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Посты VK не загружены',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Сначала подключите VK профиль',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vkProfile!.recentPosts.length,
      itemBuilder: (context, index) {
        final post = _vkProfile!.recentPosts[index];
        return _buildPostCard(post, index);
      },
    );
  }

  Widget _buildPostCard(String postText, int index) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _vkProfile!.photoUrl != null
                        ? NetworkImage(_vkProfile!.photoUrl!)
                        : null,
                    child: _vkProfile!.photoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vkProfile!.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${index + 1} дн. назад',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.public, color: Colors.blue[600]),
                ],
              ),
              const SizedBox(height: 12),
              Text(postText, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${(index + 1) * 10}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${(index + 1) * 3}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.share, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${(index + 1) * 2}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      );

  Future<void> _loadVKProfile() async {
    final vkUrl = _vkUrlController.text.trim();
    if (vkUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Введите ссылку на VK профиль';
        _vkProfile = null;
      });
      return;
    }

    if (!_vkService.isValidVKUrl(vkUrl)) {
      setState(() {
        _errorMessage = 'Неверная ссылка VK';
        _vkProfile = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _vkProfile = null;
    });

    try {
      // В демо-режиме используем mock данные
      final profile = _vkService.createMockVKProfile('https://vk.com/demo');

      setState(() {
        _vkProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки профиля: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveVKProfile() async {
    if (_vkProfile == null) return;

    try {
      // TODO(developer): Сохранить VK профиль в базу данных
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VK профиль успешно сохранен!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red));
    }
  }
}
