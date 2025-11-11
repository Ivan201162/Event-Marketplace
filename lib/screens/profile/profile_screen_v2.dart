import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/debug_log.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/chip_badge.dart';
import '../../ui/components/outlined_button_x.dart';

/// Profile 2.0 в VK-стиле с табами
class ProfileScreenV2 extends StatefulWidget {
  final String? userId; // null = свой профиль
  const ProfileScreenV2({this.userId, super.key});

  @override
  State<ProfileScreenV2> createState() => _ProfileScreenV2State();
}

class _ProfileScreenV2State extends State<ProfileScreenV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _profileUserId;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _profileUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _isCurrentUser = widget.userId == null;
    _tabController = TabController(length: 5, vsync: this);
    debugLog('PROFILE_OPENED:${_profileUserId ?? "null"}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_profileUserId == null) {
      return const Scaffold(body: Center(child: Text('Пользователь не найден')));
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_profileUserId!)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Scaffold(body: Center(child: Text('Профиль не найден')));
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(data, innerBoxIsScrolled),
              _buildProfileHeader(data),
              _buildStatsSection(data),
              _buildActionButtons(data),
              _buildTabBar(),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildReelsTab(),
                _buildReviewsTab(),
                _buildPricingTab(),
                _buildCalendarTab(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> data, bool innerBoxIsScrolled) {
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final photoUrl = data['photoUrl'] as String?;

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: photoUrl != null
            ? Image.network(photoUrl, fit: BoxFit.cover)
            : Container(color: Colors.grey[300]),
      ),
      actions: _isCurrentUser
          ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // TODO: Редактировать профиль
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  // TODO: Создать контент (Post/Reel/Story/Idea)
                },
              ),
            ]
          : null,
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final city = data['city'] ?? '';
    final roles = (data['roles'] as List?) ?? [];
    final photoUrl = data['photoUrl'] as String?;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(city, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (roles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: roles.take(3).map((role) {
                  return ChipBadge(label: role.toString());
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> data) {
    // TODO: Получить реальные данные из подписок/заказов
    final followers = data['followersCount'] ?? 0;
    final following = data['followingCount'] ?? 0;
    final orders = data['ordersCount'] ?? 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Подписчики', followers),
            _buildStatItem('Подписки', following),
            _buildStatItem('Заказы', orders),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    if (_isCurrentUser) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButtonX(
                  text: 'Редактировать профиль',
                  onTap: () {
                    // TODO: Редактировать профиль
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButtonX(
                  text: 'Создать контент',
                  onTap: () {
                    // TODO: Меню: Post/Reel/Story/Idea
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Чужой профиль
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButtonX(
                text: 'Подписаться',
                onTap: () {
                  // TODO: Подписаться/Отписаться
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButtonX(
                text: 'Написать',
                onTap: () {
                  // TODO: Открыть чат
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButtonX(
                text: 'Заказать',
                onTap: () {
                  // TODO: Открыть календарь для бронирования
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on)), // Посты
            Tab(icon: Icon(Icons.play_circle_outline)), // Рилсы
            Tab(icon: Icon(Icons.star_outline)), // Отзывы
            Tab(icon: Icon(Icons.attach_money)), // Прайс
            Tab(icon: Icon(Icons.event)), // Календарь
          ],
          onTap: (index) {
            final tabNames = ['posts', 'reels', 'reviews', 'pricing', 'calendar'];
            if (index < tabNames.length) {
              debugLog('PROFILE_TABS:${tabNames[index]}');
            }
          },
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: _profileUserId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snap.data!.docs;
        if (posts.isEmpty) {
          return const Center(child: Text('Постов пока нет'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (ctx, i) {
            final post = posts[i].data() as Map<String, dynamic>;
            final images = (post['images'] as List?) ?? [];
            if (images.isEmpty) {
              return Container(color: Colors.grey[200]);
            }
            return Image.network(
              images[0] as String,
              fit: BoxFit.cover,
            );
          },
        );
      },
    );
  }

  Widget _buildReelsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reels')
          .where('authorId', isEqualTo: _profileUserId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reels = snap.data!.docs;
        if (reels.isEmpty) {
          return const Center(child: Text('Рилсов пока нет'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: reels.length,
          itemBuilder: (ctx, i) {
            final reel = reels[i].data() as Map<String, dynamic>;
            final thumbnail = reel['thumbnail'] as String?;
            return Stack(
              fit: StackFit.expand,
              children: [
                thumbnail != null
                    ? Image.network(thumbnail, fit: BoxFit.cover)
                    : Container(color: Colors.grey[200]),
                const Center(
                  child: Icon(Icons.play_circle_filled, color: Colors.white, size: 40),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('specialistId', isEqualTo: _profileUserId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snap.data!.docs;
        debugLog('REVIEWS_LOADED:${reviews.length}');

        if (reviews.isEmpty) {
          return const Center(child: Text('Отзывов пока нет'));
        }

        // Средняя оценка
        double avgRating = 0;
        if (reviews.isNotEmpty) {
          final sum = reviews.fold<double>(
            0,
            (sum, doc) => sum + ((doc.data() as Map)['rating'] as num? ?? 0).toDouble(),
          );
          avgRating = sum / reviews.length;
        }

        return Column(
          children: [
            if (avgRating > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (ctx, i) {
                  final review = reviews[i].data() as Map<String, dynamic>;
                  return _buildReviewCard(review);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = review['text'] as String? ?? '';
    final createdAt = review['createdAt'] as Timestamp?;
    final authorId = review['authorId'] as String?;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
              if (createdAt != null) ...[
                const Spacer(),
                Text(
                  _formatDate(createdAt.toDate()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(text),
          ],
          if (authorId != null) ...[
            const SizedBox(height: 8),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const SizedBox.shrink();
                }
                final author = snap.data!.data() as Map<String, dynamic>?;
                if (author == null) {
                  return const SizedBox.shrink();
                }
                final firstName = author['firstName'] ?? '';
                final lastName = author['lastName'] ?? '';
                final photoUrl = author['photoUrl'] as String?;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 8),
                    Text('$firstName $lastName', style: const TextStyle(fontSize: 12)),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('specialist_pricing')
          .doc(_profileUserId)
          .collection('base')
          .where('hidden', isEqualTo: false)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prices = snap.data!.docs;
        if (prices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Прайсы не указаны',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prices.length,
          itemBuilder: (ctx, i) {
            final price = prices[i].data() as Map<String, dynamic>;
            return FutureBuilder<Map<String, dynamic>>(
              future: _getPriceRating(price),
              builder: (ctx, ratingSnap) {
                return _buildPricingCard(price, !_isCurrentUser, ratingSnap.data);
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getPriceRating(Map<String, dynamic> price) async {
    if (_isCurrentUser) {
      return {};
    }

    try {
      final roleId = price['roleId'] as String?;
      final priceFrom = (price['priceFrom'] as num?)?.toInt() ?? 0;
      
      if (roleId == null || priceFrom == 0) {
        return {};
      }

      // Получаем город специалиста
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_profileUserId)
          .get();
      final city = userDoc.data()?['city'] as String?;

      if (city == null || city.isEmpty) {
        return {};
      }

      // Вычисляем статистику перцентилей
      final pricesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('base')
          .where('roleId', isEqualTo: roleId)
          .where('hidden', isEqualTo: false)
          .get();

      final cityPrices = <int>[];
      for (var doc in pricesSnapshot.docs) {
        final specialistId = doc.reference.parent.parent?.id;
        if (specialistId == null) continue;

        final specialistDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(specialistId)
            .get();
        final specialistCity = specialistDoc.data()?['city'] as String?;
        
        if (specialistCity?.toLowerCase() == city.toLowerCase()) {
          final p = (doc.data()['priceFrom'] as num?)?.toInt();
          if (p != null && p > 0) {
            cityPrices.add(p);
          }
        }
      }

      if (cityPrices.length < 3) {
        return {}; // Недостаточно данных
      }

      cityPrices.sort();
      final p25 = cityPrices[(cityPrices.length * 0.25).floor()];
      final p50 = cityPrices[(cityPrices.length * 0.5).floor()];
      final p75 = cityPrices[(cityPrices.length * 0.75).floor()];

      String rating;
      String marker;
      if (priceFrom <= p25) {
        rating = 'excellent';
        marker = '🟢';
      } else if (priceFrom >= p75) {
        rating = 'high';
        marker = '🔴';
      } else {
        rating = 'average';
        marker = '🟡';
      }

      debugLog('PRICE_RATING:${_profileUserId}:$roleId:$marker');
      return {'rating': rating, 'marker': marker};
    } catch (e) {
      debugLog('PRICE_RATING_ERR:$e');
      return {};
    }
  }

  Widget _buildPricingCard(
    Map<String, dynamic> price,
    bool showMarketRating,
    Map<String, dynamic>? ratingData,
  ) {
    final title = price['title'] as String? ?? price['eventType'] as String? ?? 'Услуга';
    final priceFrom = (price['priceFrom'] as num?)?.toInt() ?? 0;
    final baseHours = (price['baseHours'] as num?)?.toInt() ?? 0;
    final rating = ratingData?['rating'] as String?;
    final marker = ratingData?['marker'] as String? ?? '';

    String ratingLabel = '';
    Color ratingColor = Colors.grey;
    if (rating == 'excellent') {
      ratingLabel = 'Отличная';
      ratingColor = Colors.green;
    } else if (rating == 'average') {
      ratingLabel = 'Средняя';
      ratingColor = Colors.orange;
    } else if (rating == 'high') {
      ratingLabel = 'Высокая';
      ratingColor = Colors.red;
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (showMarketRating && rating != null && marker.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$marker $ratingLabel', style: TextStyle(fontSize: 12, color: ratingColor)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Ориентировочно: $priceFrom ₽',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              if (baseHours > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'за $baseHours ч.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    if (_profileUserId == null) {
      return const Center(child: Text('Пользователь не найден'));
    }

    // Для клиентов показываем календарь специалиста (только цвета)
    // Для специалиста - полный календарь с управлением
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('specialist_calendar')
          .doc(_profileUserId)
          .collection('days')
          .where('date', isGreaterThanOrEqualTo: DateTime.now().toIso8601String().split('T')[0])
          .orderBy('date')
          .limit(90)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final days = snap.data!.docs;
        final daysMap = <String, Map<String, dynamic>>{};
        for (var doc in days) {
          final date = doc.id;
          daysMap[date] = doc.data() as Map<String, dynamic>;
        }

        return _buildCalendarGrid(daysMap);
      },
    );
  }

  Widget _buildCalendarGrid(Map<String, dynamic> daysMap) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final weekDayOfFirst = firstDay.weekday == 7 ? 0 : firstDay.weekday - 1;

    return Column(
      children: [
        // Легенда
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.green, 'Свободно'),
              _buildLegendItem(Colors.orange, 'Есть заявки'),
              _buildLegendItem(Colors.red, 'Занято'),
            ],
          ),
        ),
        // Календарь
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: weekDayOfFirst + daysInMonth,
            itemBuilder: (ctx, i) {
              if (i < weekDayOfFirst) {
                return const SizedBox.shrink();
              }

              final day = i - weekDayOfFirst + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final dateStr = date.toIso8601String().split('T')[0];
              final dayData = daysMap[dateStr];

              Color dayColor = Colors.green; // Свободно
              String? statusText;
              
              if (dayData != null) {
                final status = dayData['status'] as String?;
                final pendingCount = (dayData['pendingCount'] as num?)?.toInt() ?? 0;
                final acceptedBookingId = dayData['acceptedBookingId'] as String?;

                if (acceptedBookingId != null || status == 'confirmed') {
                  dayColor = Colors.red; // Занято
                  statusText = 'Занято';
                } else if (pendingCount > 0 || status == 'pending') {
                  dayColor = Colors.orange; // Есть заявки
                  statusText = pendingCount > 0 ? '+$pendingCount' : null;
                }
              }

              final isToday = date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

              return GestureDetector(
                onTap: () {
                  if (!isPast && !_isCurrentUser) {
                    // Для клиента - открыть форму заказа
                    debugLog('CAL_DAY_TAP:$dateStr:${dayData?['status'] ?? 'free'}:${dayData?['pendingCount'] ?? 0}');
                    // TODO: Открыть форму заказа
                  } else if (_isCurrentUser && dayData != null) {
                    // Для специалиста - показать список заявок
                    debugLog('CAL_DAY_TAP:$dateStr:${dayData['status']}:${dayData['pendingCount'] ?? 0}');
                    // TODO: Показать список pending заявок
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey[200]
                        : dayColor.withOpacity(0.2),
                    border: Border.all(
                      color: isToday ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isPast ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (statusText != null)
                        Text(
                          statusText,
                          style: const TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Сегодня';
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

