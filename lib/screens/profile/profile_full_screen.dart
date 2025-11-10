import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/constants/specialist_roles.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/widgets/calendar_tab_content.dart';
import 'package:event_marketplace_app/widgets/pricing_tab_content.dart';
import 'package:event_marketplace_app/theme/typography.dart';
import 'package:event_marketplace_app/theme/colors.dart';
import 'package:event_marketplace_app/ui/components/outlined_button_x.dart';
import 'package:event_marketplace_app/ui/components/chip_badge.dart';
import 'package:event_marketplace_app/ui/components/divider_thin.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Полноценный профиль с вкладками
class ProfileFullScreen extends ConsumerStatefulWidget {
  const ProfileFullScreen({
    required this.userId,
    super.key,
  });
  final String userId;

  @override
  ConsumerState<ProfileFullScreen> createState() => _ProfileFullScreenState();
}

class _ProfileFullScreenState extends ConsumerState<ProfileFullScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DocumentSnapshot? _lastReviewDoc;
  bool _isLoadingMore = false;

  bool _isSpecialist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // posts, reels, reviews, price, calendar
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabNames = ['posts', 'reels', 'reviews', 'price', 'calendar'];
        if (_tabController.index < tabNames.length) {
          debugLog("PROFILE_TABS:${tabNames[_tabController.index]}");
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileStartTime = DateTime.now().millisecondsSinceEpoch;
      debugLog("PROFILE_OPENED:${widget.userId}");
      // Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'open_profile',
        parameters: {'profile_id': widget.userId},
      ).catchError((e) => debugPrint('Analytics error: $e'));
      _loadUserData().then((_) {
        final profileLoadTime = DateTime.now().millisecondsSinceEpoch - profileStartTime;
        debugLog("PERF_PROFILE_LOAD:$profileLoadTime");
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final isSpecialist = data['isSpecialist'] ?? false;
        if (mounted && isSpecialist != _isSpecialist) {
          setState(() {
            _isSpecialist = isSpecialist;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<double> _getUserRating(String uid) async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('specialistId', isEqualTo: uid)
          .get();
      if (reviewsSnapshot.docs.isEmpty) return 0.0;
      final ratings = reviewsSnapshot.docs
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .where((r) => r > 0)
          .toList();
      if (ratings.isEmpty) return 0.0;
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == widget.userId;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Пользователь не найден'));
            }

            try {
              final user = AppUser.fromFirestore(snapshot.data!);
              
              // Обновляем статус специалиста
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final userIsSpecialist = (userData?['isSpecialist'] as bool?) ?? false;
              if (mounted && userIsSpecialist != _isSpecialist) {
                setState(() {
                  _isSpecialist = userIsSpecialist;
                });
              }
              
              // Проверка статуса подписки (если не свой профиль)
              return StreamBuilder<DocumentSnapshot?>(
                stream: !isOwnProfile && currentUser != null
                    ? FirebaseFirestore.instance
                        .collection('follows')
                        .doc('${currentUser.uid}_${widget.userId}')
                        .snapshots()
                    : Stream.value(null),
                builder: (context, followSnapshot) {
                  final isFollowing = followSnapshot.hasData && followSnapshot.data?.exists == true;
                  
                  return NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        // SliverAppBar без заголовка
                        SliverAppBar(
                          expandedHeight: 0,
                          floating: false,
                          pinned: false,
                          automaticallyImplyLeading: false,
                          toolbarHeight: 0,
                          title: null,
                        ),
                        SliverToBoxAdapter(
                          child: _buildProfileHeader(user, isOwnProfile, isFollowing),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabBarDelegate(
                            TabBar(
                              controller: _tabController,
                              indicatorColor: Theme.of(context).colorScheme.primary,
                              indicatorWeight: 2,
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              tabs: const [
                                Tab(icon: Icon(Icons.grid_on)), // posts
                                Tab(icon: Icon(Icons.play_circle_outline)), // reels
                                Tab(icon: Icon(Icons.star)), // reviews
                                Tab(icon: Icon(Icons.attach_money)), // price
                                Tab(icon: Icon(Icons.event)), // calendar
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                    body: RefreshIndicator(
                      onRefresh: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.userId)
                              .get();
                          
                          await Future.delayed(const Duration(milliseconds: 300));
                          debugLog("REFRESH_OK:profile");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Обновлено'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          debugLog("REFRESH_ERR:profile:$e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка обновления: $e')),
                            );
                          }
                        }
                      },
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPostsTab(user),
                          _buildReelsTab(user),
                          _buildReviewsTab(user),
                          _buildPricesTab(user),
                          _buildCalendarTab(user),
                        ],
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              return Center(child: Text('Ошибка загрузки: $e'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user, bool isOwnProfile, bool isFollowing) {
    final userName = '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty
        ? (user.email ?? user.name ?? 'Пользователь')
        : '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        children: [
          // VK-шапка: аватар слева, имя справа
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар слева (72-84dp)
              GestureDetector(
                onTap: isOwnProfile ? () {
                  // TODO: Редактирование аватара
                } : null,
                child: CircleAvatar(
                  radius: 42, // 84dp диаметр
                  backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null || user.photoURL!.isEmpty
                      ? Icon(Icons.person, size: 42, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Имя и информация справа
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя Фамилия крупно
                    Text(
                      userName,
                      style: AppTypography.titleLg.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Город с иконкой place
                    if (user.city != null && user.city!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.city!,
                            style: AppTypography.bodySm.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Бейджи ролей (до 3)
                    if (user.roles.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.roles.take(3).map((role) {
                          final roleId = role['id'] as String? ?? '';
                          final roleLabel = role['label'] as String? ?? '';
                          return ChipBadge(
                            label: roleLabel,
                            icon: SpecialistRoles.getIcon(roleId).isNotEmpty 
                                ? null 
                                : Icons.work_outline,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Счётчики: Подписчики / Подписки / Заказы
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Подписчики', user.followersCount ?? 0),
              _buildStatColumn('Подписки', user.followingCount ?? 0),
              if (user.role == 'specialist')
                FutureBuilder<int>(
                  future: BookingService().getConfirmedBookingsCount(user.uid),
                  builder: (context, snapshot) {
                    return _buildStatColumn('Заказы', snapshot.data ?? 0);
                  },
                ),
            ],
          ),
          
          // Разделитель
          const SizedBox(height: 16),
          const DividerThin(),
          const SizedBox(height: 16),
          
          // Кнопки действий
          if (isOwnProfile)
            // Свой профиль: "Создать контент"
            OutlinedButtonX(
              text: 'Создать контент',
              icon: Icons.add_circle_outline,
              onTap: () => _showCreateContentMenu(context),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            )
          else if (user.role == 'specialist')
            // Профиль специалиста: кнопки в ряд
            Row(
              children: [
                Expanded(
                  child: OutlinedButtonX(
                    text: 'Подписаться',
                    onTap: () => _handleFollow(user),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButtonX(
                    text: 'Связаться',
                    onTap: () => _handleMessage(user),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButtonX(
                    text: 'Заказать',
                    onTap: () => _handleOrder(user),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            )
          else
            // Профиль обычного пользователя: 2 кнопки
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButtonX(
                    text: isFollowing ? 'Отписаться' : 'Подписаться',
                    icon: isFollowing ? Icons.person_remove : Icons.person_add,
                    onTap: () => _handleFollow(user),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButtonX(
                    text: 'Написать',
                    icon: Icons.message,
                    onTap: () => _handleMessage(user),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTypography.titleMd.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(AppUser user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Пока нет постов',
                style: AppTypography.bodyMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>?;
            final imageUrl = data?['imageUrl'] ?? (data?['images'] as List?)?.first;
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: imageUrl != null
                  ? Image.network(imageUrl.toString(), fit: BoxFit.cover)
                  : Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            );
          },
        );
      },
    );
  }

  Widget _buildReelsTab(AppUser user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reels')
          .where('authorId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reels = snapshot.data!.docs;
        if (reels.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Пока нет рилсов',
                style: AppTypography.bodyMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            final data = reel.data() as Map<String, dynamic>?;
            final thumbnail = data?['thumbnailUrl'] ?? data?['videoUrl'];
            return Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(thumbnail.toString(), fit: BoxFit.cover),
                    )
                  : Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab(AppUser user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == widget.userId;
    final canAddReview = !isOwnProfile && user.role == 'specialist' && currentUser != null;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('specialistId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!.docs;
        
        double avgRating = 0;
        if (reviews.isNotEmpty) {
          final sum = reviews.fold<double>(
            0,
            (sum, doc) => sum + ((doc.data() as Map)['rating'] as num? ?? 0).toDouble(),
          );
          avgRating = sum / reviews.length;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugLog("REVIEWS_LOADED:${reviews.length}");
        });

        return Column(
          children: [
            // Шапка с рейтингом
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        avgRating > 0 ? avgRating.toStringAsFixed(1) : '0.0',
                        style: AppTypography.titleLg.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${reviews.length} ${_getReviewsWord(reviews.length)})',
                        style: AppTypography.bodyMd.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (canAddReview) ...[
                    const SizedBox(height: 12),
                    OutlinedButtonX(
                      text: 'Оставить отзыв',
                      icon: Icons.add,
                      onTap: () => _showAddReviewDialog(user),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ],
                ],
              ),
            ),
            // Список отзывов
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final data = review.data() as Map;
                  return _buildReviewCard(data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricesTab(AppUser user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("PRICE_CARD_SHOWN:${user.uid}");
    });
    return PricingTabContent(
      user: user,
      isOwnProfile: widget.userId == FirebaseAuth.instance.currentUser?.uid,
    );
  }

  Widget _buildCalendarTab(AppUser user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("CAL_OPENED:${user.uid}");
    });
    return CalendarTabContent(specialistId: user.uid);
  }

  Widget _buildReviewCard(Map data) {
    final authorName = data['authorName'] ?? 'Аноним';
    final authorAvatar = data['authorAvatar'];
    final rating = (data['rating'] as num? ?? 0).toInt();
    final text = data['text'] ?? '';
    final photos = (data['photos'] as List?)?.cast<String>() ?? [];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: authorAvatar != null
                    ? NetworkImage(authorAvatar)
                    : null,
                child: authorAvatar == null
                    ? Icon(Icons.person, size: 24, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: AppTypography.titleMd.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy', 'ru').format(createdAt),
                        style: AppTypography.bodySm.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: AppTypography.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length > 4 ? 4 : photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(photos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getReviewsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'отзыв';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'отзыва';
    }
    return 'отзывов';
  }

  Future<void> _handleFollow(AppUser user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final followRef = FirebaseFirestore.instance
          .collection('follows')
          .doc('${currentUser.uid}_${user.uid}');
      final followDoc = await followRef.get();

      final batch = FirebaseFirestore.instance.batch();

      if (followDoc.exists) {
        batch.delete(followRef);
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
          {'followingCount': FieldValue.increment(-1)},
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {'followersCount': FieldValue.increment(-1)},
        );
      } else {
        batch.set(followRef, {
          'followerId': currentUser.uid,
          'followedId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
          {'followingCount': FieldValue.increment(1)},
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {'followersCount': FieldValue.increment(1)},
        );
      }

      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _handleMessage(AppUser user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatsQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String? chatId;
      for (final chatDoc in chatsQuery.docs) {
        final participants = (chatDoc.data()['participants'] as List?)?.cast<String>() ?? [];
        if (participants.contains(user.uid) && participants.length == 2) {
          chatId = chatDoc.id;
          break;
        }
      }

      if (chatId == null) {
        final newChat = await FirebaseFirestore.instance.collection('chats').add({
          'participants': [currentUser.uid, user.uid],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        chatId = newChat.id;
      }

      if (mounted) {
        context.push('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _handleOrder(AppUser user) {
    final userName = '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty
        ? (user.email ?? user.name ?? 'Специалист')
        : '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim();
    context.push('/booking/calendar/${user.uid}?name=$userName');
  }

  Future<void> _showAddReviewDialog(AppUser specialist) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;

    int rating = 0;
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Оставить отзыв',
                  style: AppTypography.titleLg.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Рейтинг:',
                  style: AppTypography.bodyMd.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => rating = index + 1),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: 'Текст отзыва',
                    hintText: 'Опишите ваш опыт...',
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Минимум 5 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButtonX(
                    text: 'Отправить',
                    onTap: () async {
                      if (rating == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Выберите рейтинг')),
                        );
                        return;
                      }
                      if (!formKey.currentState!.validate()) return;

                      try {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .get();
                        final userData = userDoc.data();
                        final firstName = userData?['firstName'] as String?;
                        final lastName = userData?['lastName'] as String?;
                        final authorName = (firstName != null && lastName != null)
                            ? '$firstName $lastName'
                            : (userData?['name'] as String? ?? currentUser.displayName ?? 'Пользователь');
                        final authorPhotoUrl = userData?['photoURL'] ?? currentUser.photoURL;

                        await FirebaseFirestore.instance.collection('reviews').add({
                          'specialistId': specialist.uid,
                          'authorId': currentUser.uid,
                          'authorName': authorName,
                          'authorPhotoUrl': authorPhotoUrl,
                          'rating': rating,
                          'text': textController.text.trim(),
                          'photos': [],
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        final reviews = await FirebaseFirestore.instance
                            .collection('reviews')
                            .where('specialistId', isEqualTo: specialist.uid)
                            .get();
                        final avgRating = reviews.docs.fold<double>(
                          0.0,
                          (sum, doc) => sum + ((doc.data()['rating'] as num? ?? 0).toDouble()),
                        ) / reviews.docs.length;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(specialist.uid)
                            .update({'rating': avgRating});

                        debugLog("REVIEW_ADDED:${specialist.uid}");
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Отзыв добавлен')),
                          );
                        }
                      } catch (e) {
                        debugLog("REVIEW_ERR:${e.toString()}");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateContentMenu(BuildContext context) {
    debugLog("CREATE_MENU_OPENED");
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Пост'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/post');
                debugLog("CONTENT_CREATE_SELECTED:post");
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Рилс'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/reel');
                debugLog("CONTENT_CREATE_SELECTED:reel");
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('Сторис'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/story');
                debugLog("CONTENT_CREATE_SELECTED:story");
              },
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Идея'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/idea');
                debugLog("CONTENT_CREATE_SELECTED:idea");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        boxShadow: AppColors.lightShadow,
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
