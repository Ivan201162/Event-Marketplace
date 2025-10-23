import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/host_profile.dart';
import '../widgets/host_profile/availability_block.dart';
import '../widgets/host_profile/avatar_block.dart';
import '../widgets/host_profile/info_block.dart';
import '../widgets/host_profile/reviews_block.dart';

/// Страница профиля ведущего мероприятия
class HostProfileScreen extends StatefulWidget {
  const HostProfileScreen({super.key, required this.hostId});
  final String hostId;

  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  HostProfile? _host;
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHostData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  Future<void> _loadHostData() async {
    // TODO(developer): Заменить на реальную загрузку данных из API/Firebase
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _host = MockHostData.sampleHost;
      _isLoading = false;
    });

    // Запуск анимаций
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Профиль ведущего'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProfile,
            tooltip: 'Поделиться',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: 'Добавить в избранное',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _host == null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _host != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor)),
          const SizedBox(height: 16),
          Text(
            'Загрузка профиля...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            'Не удалось загрузить профиль ведущего',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadHostData();
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_host == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Блок с аватаром
              AvatarBlock(host: _host!, onPhotoTap: _showPhotoDialog),

              const SizedBox(height: 16),

              // Информационный блок
              InfoBlock(host: _host!),

              const SizedBox(height: 16),

              // Блок с отзывами
              ReviewsBlock(
                  reviews: _host!.reviews, onViewAllReviews: _viewAllReviews),

              const SizedBox(height: 16),

              // Блок с доступными датами
              AvailabilityBlock(
                availableDates: _host!.availableDates,
                selectedDate: _selectedDate,
                onDateSelected: _selectDate,
              ),

              const SizedBox(height: 100), // Отступ для bottom bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Кнопка "Связаться"
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _contactHost,
                icon: const Icon(Icons.message),
                label: const Text('Связаться'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Кнопка "Откликнуться"
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _respondToHost,
                icon: const Icon(Icons.handshake),
                label: const Text('Откликнуться'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Методы для обработки действий
  void _shareProfile() {
    // TODO(developer): Реализовать функционал шаринга
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(
        content: Text('Функция "Поделиться" будет реализована')));
  }

  void _toggleFavorite() {
    // TODO(developer): Реализовать добавление в избранное
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Функция "Избранное" будет реализована')));
  }

  void _showPhotoDialog() {
    if (_host?.photoUrl == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  _host!.photoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 64, color: Colors.red),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAllReviews() {
    // TODO(developer): Переход на страницу всех отзывов
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Переход к полному списку отзывов')));
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    // TODO(developer): Сохранить выбранную дату для дальнейшего использования
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text('Выбрана дата: ${_formatDate(date)}')));
  }

  void _contactHost() {
    // TODO(developer): Переход к чату с ведущим
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Переход к чату с ведущим')));
  }

  void _respondToHost() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите дату для мероприятия'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO(developer): Переход к форме отклика
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Отклик на дату: ${_formatDate(_selectedDate!)}')));
  }

  String _formatDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
