import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/constants/specialist_roles.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/widgets/calendar_tab_content.dart';
import 'package:event_marketplace_app/widgets/pricing_tab_content.dart';
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
    _tabController = TabController(length: 5, vsync: this); // posts, reels, reviews, prices, calendar
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabNames = ['posts', 'reels', 'reviews', 'prices', 'calendar'];
        if (_tabController.index < tabNames.length) {
          debugLog("PROFILE_TABS:${tabNames[_tabController.index]}");
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugLog("PROFILE_OPENED:${widget.userId}");
      _loadUserData();
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
                        // SliverAppBar без заголовка (чтобы не было дублирования имени)
                        SliverAppBar(
                          expandedHeight: 0,
                          floating: false,
                          pinned: false,
                          automaticallyImplyLeading: false,
                          toolbarHeight: 0,
                          title: null, // Убираем заголовок полностью
                        ),
                        SliverToBoxAdapter(
                          child: _buildProfileHeader(user, isOwnProfile, isFollowing),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabBarDelegate(
                            TabBar(
                              controller: _tabController,
                              tabs: _isSpecialist
                                  ? const [
                                      Tab(icon: Icon(Icons.grid_on)),
                                      Tab(icon: Icon(Icons.play_circle_outline)),
                                      Tab(icon: Icon(Icons.star)),
                                      Tab(icon: Icon(Icons.attach_money)),
                                      Tab(icon: Icon(Icons.event)),
                                    ]
                                  : const [
                                      Tab(icon: Icon(Icons.grid_on)),
                                      Tab(icon: Icon(Icons.play_circle_outline)),
                                      Tab(icon: Icon(Icons.star)),
                                      Tab(icon: Icon(Icons.event)),
                                      Tab(icon: Icon(Icons.event)),
                                    ],
                            ),
                          ),
                        ),
                        // Отступ для тени
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 1),
                        ),
                      ];
                    },
                    body: RefreshIndicator(
                      onRefresh: () async {
                        try {
                          // Обновляем данные профиля
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
                          if (_isSpecialist) _buildPricesTab(user) else _buildPostsTab(user),
                          if (_isSpecialist && isOwnProfile) _buildCalendarTab(user) else _buildPostsTab(user),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар слева, имя по центру (стиль ВК)
          Row(
            children: [
              // Аватар слева
              GestureDetector(
                onTap: isOwnProfile ? () {
                  // TODO: Редактирование аватара
                } : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null || user.photoURL!.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Имя и город по центру
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Имя Фамилия крупно, по центру (VK стиль)
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    const SizedBox(height: 8),
                    // Город с иконкой 🏙️
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🏙️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          user.city ?? 'Город не указан',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    // Бейджи ролей
                    if (user.roles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: user.roles.take(3).map((role) {
                          final roleId = role['id'] as String? ?? '';
                          final roleLabel = role['label'] as String? ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getRoleIcon(roleId),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  roleLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Счётчики
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
          
          // Bio (если не пусто)
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.bio!,
                style: const TextStyle(fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Кнопки действий
          if (isOwnProfile)
            // Свой профиль: "Редактировать профиль" + "Настройки бронирований" (если specialist)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Редактировать профиль'),
                    onPressed: () {
                      debugLog("PROFILE_EDIT_OPENED");
                      context.push('/profile/edit');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (user.role == 'specialist' || _isSpecialist) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings, size: 20),
                      label: const Text('Настройки бронирований'),
                      onPressed: () {
                        debugLog("BOOKING_SETTINGS_OPENED");
                        context.push('/profile/booking-settings');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else if (user.role == 'specialist')
            // Профиль специалиста: 3 кнопки
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add, size: 20),
                    label: Text(isFollowing ? 'Отписаться' : 'Подписаться'),
                    onPressed: () => _handleFollow(user),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Написать'),
                        onPressed: () => _handleMessage(user),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text('Заказать'),
                        onPressed: () => _handleOrder(user),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // Профиль обычного пользователя: 2 кнопки
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add, size: 20),
                    label: Text(isFollowing ? 'Отписаться' : 'Подписаться'),
                    onPressed: () => _handleFollow(user),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message, size: 20),
                    label: const Text('Написать'),
                    onPressed: () => _handleMessage(user),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Пока нет постов', style: TextStyle(color: Colors.grey)),
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
              color: Colors.grey[200],
              child: imageUrl != null
                  ? Image.network(imageUrl.toString(), fit: BoxFit.cover)
                  : const Icon(Icons.image),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Пока нет рилсов', style: TextStyle(color: Colors.grey)),
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
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(thumbnail.toString(), fit: BoxFit.cover),
                    )
                  : const Center(child: Icon(Icons.play_circle_outline, size: 48)),
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
        
        // Вычисляем средний рейтинг
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
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        avgRating > 0 ? avgRating.toStringAsFixed(1) : '0.0',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${reviews.length} ${_getReviewsWord(reviews.length)})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                  if (canAddReview) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Оставить отзыв'),
                      onPressed: () => _showAddReviewDialog(user),
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
    return PricingTabContent(
      user: user,
      isOwnProfile: widget.userId == FirebaseAuth.instance.currentUser?.uid,
    );
  }

  Widget _buildCalendarTab(AppUser user) {
    return const CalendarTabContent();
  }

  Widget _buildReviewCard(Map data) {
    final authorName = data['authorName'] ?? 'Аноним';
    final authorAvatar = data['authorAvatar'];
    final rating = (data['rating'] as num? ?? 0).toInt();
    final text = data['text'] ?? '';
    final photos = (data['photos'] as List?)?.cast<String>() ?? [];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      ? const Icon(Icons.person, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                style: const TextStyle(fontSize: 14, height: 1.5),
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
        // Отписаться
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
        // Подписаться
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
      // Ищем существующий чат
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
        // Создаём новый чат
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
                const Text(
                  'Оставить отзыв',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Рейтинг:'),
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
                  decoration: const InputDecoration(
                    labelText: 'Текст отзыва',
                    border: OutlineInputBorder(),
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
                  child: ElevatedButton(
                    onPressed: () async {
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

                        // Пересчитываем средний рейтинг
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
                    child: const Text('Отправить'),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

