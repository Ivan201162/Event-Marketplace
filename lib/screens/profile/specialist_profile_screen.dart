import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_marketplace_app/models/specialist.dart';
import 'package:event_marketplace_app/widgets/avatar_widget.dart';
import 'package:event_marketplace_app/widgets/booking_widget.dart';
import 'package:event_marketplace_app/widgets/portfolio_grid.dart';
import 'package:event_marketplace_app/widgets/reviews_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Specialist profile screen with portfolio and booking
class SpecialistProfileScreen extends ConsumerStatefulWidget {

  const SpecialistProfileScreen({required this.specialistId, super.key});
  final String specialistId;

  @override
  ConsumerState<SpecialistProfileScreen> createState() =>
      _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState
    extends ConsumerState<SpecialistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialistAsync =
        ref.watch(specialistByIdProvider(widget.specialistId));

    return Scaffold(
      body: specialistAsync.when(
        data: (specialist) {
          if (specialist == null) {
            return const Center(child: Text('Специалист не найден'));
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [_buildSliverAppBar(specialist), _buildSliverTabBar()];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(specialist),
                _buildPortfolioTab(specialist),
                _buildReviewsTab(specialist),
                _buildServicesTab(specialist),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки профиля',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(specialistByIdProvider(widget.specialistId));
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: specialistAsync.when(
        data: (specialist) {
          if (specialist == null) return null;
          return _buildBottomBar(specialist);
        },
        loading: () => null,
        error: (error, stack) => null,
      ),
    );
  }

  Widget _buildSliverAppBar(Specialist specialist) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (specialist.avatarUrl != null &&
                specialist.avatarUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: specialist.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 100),),
              )
            else
              Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 100),),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Profile info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarWidget(
                        imageUrl: specialist.avatarUrl,
                        name: specialist.name,
                        size: 60,
                        showBorder: true,
                        borderColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              specialist.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              specialist.specialization,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16,),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 16,),
                                const SizedBox(width: 4),
                                Text(
                                  specialist.city,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14,),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // TODO: Add to favorites
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
                const SnackBar(content: Text('Добавлено в избранное')),);
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Share profile
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(
                content: Text('Профиль скопирован в буфер обмена'),),);
          },
        ),
      ],
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'О специалисте'),
            Tab(text: 'Портфолио'),
            Tab(text: 'Отзывы'),
            Tab(text: 'Услуги'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(Specialist specialist) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and stats
          _buildRatingCard(specialist),

          const SizedBox(height: 16),

          // Description
          if (specialist.description != null &&
              specialist.description!.isNotEmpty)
            _buildDescriptionCard(specialist),

          const SizedBox(height: 16),

          // Experience
          _buildExperienceCard(specialist),

          const SizedBox(height: 16),

          // Contact info
          _buildContactCard(specialist),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(Specialist specialist) {
    return PortfolioGrid(
      portfolio: specialist.portfolio,
      onImageTap: (imageUrl) {
        // TODO: Show full screen image
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Просмотр: $imageUrl')));
      },
    );
  }

  Widget _buildReviewsTab(Specialist specialist) {
    return ReviewsList(
      specialistId: specialist.id,
      onWriteReview: () {
        // TODO: Show write review dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(
            content: Text('Написание отзыва пока не реализовано'),),);
      },
    );
  }

  Widget _buildServicesTab(Specialist specialist) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Услуги и цены',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
          const SizedBox(height: 16),
          if (specialist.services.isNotEmpty)
            ...specialist.services
                .map((service) => _buildServiceCard(service, specialist))
          else
            const Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Услуги не указаны'),),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(Specialist specialist) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  specialist.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < specialist.rating.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.orange,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${specialist.completedEvents} выполненных заказов',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500,),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Опыт: ${specialist.experienceText}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'От ${specialist.formattedPrice}/час',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(Specialist specialist) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'О специалисте',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(specialist.description!, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(Specialist specialist) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Опыт работы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 8),
            Text(specialist.experienceText,
                style: const TextStyle(fontSize: 16),),
            if (specialist.languages.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Языки:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: specialist.languages
                    .map(
                      (language) => Chip(
                        label: Text(language),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Specialist specialist) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (specialist.contactInfo.isNotEmpty)
              ...specialist.contactInfo.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(_getContactIcon(entry.key), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_getContactLabel(entry.key)}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text('Контактная информация не указана'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String service, Specialist specialist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.work),
        title: Text(service),
        trailing: Text(
          'от ${specialist.formattedPrice}/час',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        onTap: () {
          // TODO: Show service details
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Услуга: $service')));
        },
      ),
    );
  }

  Widget _buildBottomBar(Specialist specialist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'от ${specialist.formattedPrice}/час',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  specialist.isAvailable ? 'Доступен' : 'Занят',
                  style: TextStyle(
                    fontSize: 14,
                    color: specialist.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: specialist.isAvailable
                ? () {
                    _showBookingDialog(specialist);
                  }
                : null,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Забронировать'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(Specialist specialist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookingWidget(
        specialist: specialist,
        onBookingConfirmed: (booking) {
          // TODO: Process booking
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
              const SnackBar(content: Text('Бронирование создано!')),);
        },
      ),
    );
  }

  IconData _getContactIcon(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'telegram':
        return Icons.telegram;
      case 'whatsapp':
        return Icons.whatsapp;
      default:
        return Icons.contact_page;
    }
  }

  String _getContactLabel(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return 'Телефон';
      case 'email':
        return 'Email';
      case 'telegram':
        return 'Telegram';
      case 'whatsapp':
        return 'WhatsApp';
      default:
        return type;
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {

  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent,) {
    return ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar,);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
