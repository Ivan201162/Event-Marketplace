import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/app_user.dart';
import 'package:event_marketplace_app/models/post.dart';
import 'package:event_marketplace_app/models/story.dart';
import 'package:event_marketplace_app/services/follow_service.dart';
import 'package:event_marketplace_app/services/like_service.dart';
import 'package:event_marketplace_app/services/save_service.dart';
import 'package:event_marketplace_app/services/recommendation_service.dart';
import 'package:event_marketplace_app/services/analytics_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';
import 'package:event_marketplace_app/widgets/comment_list_widget.dart';
import 'package:event_marketplace_app/widgets/add_comment_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Полноценный экран ленты с Stories, постами, рилсами и рекомендациями
class FeedScreenFull extends StatefulWidget {
  const FeedScreenFull({super.key});

  @override
  State<FeedScreenFull> createState() => _FeedScreenFullState();
}

class _FeedScreenFullState extends State<FeedScreenFull> {
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FollowService _followService = FollowService();
  final LikeService _likeService = LikeService();
  final SaveService _saveService = SaveService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  List<String> _followingIds = [];
  List<Post> _posts = [];
  List<Map<String, dynamic>> _reels = [];
  List<Story> _stories = [];
  List<AppUser> _recommendations = [];
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastPostDoc;
  DocumentSnapshot? _lastReelDoc;
  String? _currentUserId;
  String? _currentUserCity;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _analyticsService.logFeedOpened();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_currentUserId == null) return;
    
    final startTime = DateTime.now().millisecondsSinceEpoch;
    setState(() => _isLoading = true);
    
    try {
      // Загружаем подписки
      _followingIds = await _followService.getFollowingIds(_currentUserId!);
      
      // Загружаем данные пользователя (город)
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _currentUserCity = (userData['city'] as String?)?.toLowerCase();
      }
      
      // Preload Stories
      await _loadStories();
      
      // Загружаем посты и рилсы (20 элементов)
      await _loadPosts();
      await _loadReels();
      
      // Если контента мало - загружаем рекомендации
      if (_posts.length + _reels.length < 5) {
        await _loadRecommendations();
      }
      
      final loadTime = DateTime.now().millisecondsSinceEpoch - startTime;
      debugLog("FEED_PAGE_LOADED:${_posts.length + _reels.length}");
      debugLog("FEED_LOADED:${_posts.length + _reels.length}");
      debugLog("PERF_FEED_LOAD:$loadTime");
      
      if (_posts.isEmpty && _reels.isEmpty) {
        debugLog("FEED_EMPTY");
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      final loadTime = DateTime.now().millisecondsSinceEpoch - startTime;
      debugLog("ERROR:feed_load:$e");
      debugLog("PERF_FEED_LOAD:$loadTime");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _loadStories() async {
    try {
      final now = Timestamp.now();
      final storiesSnapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      _stories = storiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Story.fromMap(data, doc.id);
      }).toList();
      
      // Фильтруем только Stories от подписок
      if (_followingIds.isNotEmpty) {
        _stories = _stories.where((story) => _followingIds.contains(story.authorId)).toList();
      }
    } catch (e) {
      debugPrint('Error loading stories: $e');
    }
  }

  Future<void> _loadPosts() async {
    if (_followingIds.isEmpty) {
      _posts = [];
      return;
    }
    
    try {
      // Chunking для whereIn (макс. 10 элементов)
      final chunks = <List<String>>[];
      for (var i = 0; i < _followingIds.length; i += 10) {
        final end = (i + 10).clamp(0, _followingIds.length);
        chunks.add(_followingIds.sublist(i, end));
      }
      
      final allPosts = <Post>[];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('posts')
            .where('authorId', whereIn: chunk)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        
        final chunkPosts = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return Post.fromMap(data, doc.id);
          } catch (e) {
            debugPrint('Error parsing post ${doc.id}: $e');
            return null;
          }
        }).whereType<Post>().toList();
        
        allPosts.addAll(chunkPosts);
        
        if (snapshot.docs.isNotEmpty) {
          _lastPostDoc = snapshot.docs.last;
        }
      }
      
      // Сортируем по дате
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _posts = allPosts.take(20).toList();
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
  }

  Future<void> _loadReels() async {
    if (_followingIds.isEmpty) {
      _reels = [];
      return;
    }
    
    try {
      // Chunking для whereIn
      final chunks = <List<String>>[];
      for (var i = 0; i < _followingIds.length; i += 10) {
        final end = (i + 10).clamp(0, _followingIds.length);
        chunks.add(_followingIds.sublist(i, end));
      }
      
      final allReels = <Map<String, dynamic>>[];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('reels')
            .where('authorId', whereIn: chunk)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          allReels.add({
            'id': doc.id,
            ...data,
          });
        }
        
        if (snapshot.docs.isNotEmpty) {
          _lastReelDoc = snapshot.docs.last;
        }
      }
      
      // Сортируем по дате
      allReels.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      
      _reels = allReels.take(20).toList();
    } catch (e) {
      debugPrint('Error loading reels: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || _followingIds.isEmpty || _lastPostDoc == null) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final chunks = <List<String>>[];
      for (var i = 0; i < _followingIds.length; i += 10) {
        final end = (i + 10).clamp(0, _followingIds.length);
        chunks.add(_followingIds.sublist(i, end));
      }
      
      final morePosts = <Post>[];
      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('posts')
            .where('authorId', whereIn: chunk)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(_lastPostDoc!)
            .limit(20)
            .get();
        
        final chunkPosts = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return Post.fromMap(data, doc.id);
          } catch (e) {
            return null;
          }
        }).whereType<Post>().toList();
        
        morePosts.addAll(chunkPosts);
        
        if (snapshot.docs.isNotEmpty) {
          _lastPostDoc = snapshot.docs.last;
        }
      }
      
      morePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _posts.addAll(morePosts);
        _isLoadingMore = false;
      });
      debugLog("FEED_PAGE_LOADED:${_posts.length + _reels.length}");
    } catch (e) {
      setState(() => _isLoadingMore = false);
      debugPrint('Error loading more posts: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    if (_currentUserId == null) return;
    
    try {
      // Используем RecommendationService для получения топ-10
      final recommendationService = RecommendationService();
      final recommendations = await recommendationService.getTopRecommendations(limit: 10);
      
      setState(() {
        _recommendations = recommendations;
      });
      
      debugLog("FEED_RECS_COUNT:${_recommendations.length}");
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      // Fallback на старый метод
      if (_currentUserCity != null) {
        try {
      final popularSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'specialist')
          .where('cityLower', isEqualTo: _currentUserCity)
          .orderBy('rating', descending: true)
              .limit(10)
          .get();
      
      final recommendations = <AppUser>[];
      for (final doc in popularSnapshot.docs) {
        try {
          final user = AppUser.fromFirestore(doc);
          if (!_followingIds.contains(user.uid)) {
            recommendations.add(user);
          }
        } catch (e) {
          debugPrint('Error parsing user ${doc.id}: $e');
        }
      }
      
          setState(() {
            _recommendations = recommendations.take(10).toList();
          });
        } catch (e) {
          debugPrint('Error in fallback recommendations: $e');
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePosts();
    }
  }

  Future<void> _refresh() async {
    debugLog("FEED_REFRESH");
    try {
      _lastPostDoc = null;
      _lastReelDoc = null;
      await _loadInitialData();
      debugLog("REFRESH_OK:feed");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Обновлено'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugLog("REFRESH_ERR:feed:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Stories section
              SliverToBoxAdapter(
                child: _buildStoriesSection(),
              ),
              
              // Posts and Reels
              if (_posts.isEmpty && _reels.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                ..._buildFeedItems(),
              
              // Recommendations (если контента мало)
              if (_posts.length + _reels.length < 5 && _recommendations.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildRecommendationsSection(),
                ),
              
              // Loading more indicator
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    // Stories ниже статус-бара (SafeArea top: true)
    return SafeArea(
      top: true,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _stories.length + 1, // +1 для "Ваша сторис"
          itemBuilder: (context, index) {
            if (index == 0) {
              // Первый элемент - "Ваша сторис" с плюсом
              return _buildOwnStoryItem();
            }
            final story = _stories[index - 1];
            return _buildStoryItem(story);
          },
        ),
      ),
    );
  }
  
  Widget _buildOwnStoryItem() {
    return GestureDetector(
      onTap: () {
        debugLog("STORY_CREATE_TAP");
        context.push('/create/story');
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: const Icon(Icons.add_circle_outline, size: 40),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ваша сторис',
              style: TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStoryItem(Story story) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: ClipOval(
              child: story.media.isNotEmpty
                  ? Image.network(story.media.first, fit: BoxFit.cover)
                  : (story.authorAvatar != null && story.authorAvatar!.isNotEmpty
                      ? Image.network(story.authorAvatar!, fit: BoxFit.cover)
                      : const Icon(Icons.person)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story.authorName ?? 'Пользователь',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  List<Widget> _buildFeedItems() {
    final items = <Widget>[];
    final allItems = <Map<String, dynamic>>[];
    
    // Добавляем посты
    for (final post in _posts) {
      allItems.add({
        'type': 'post',
        'data': post,
        'timestamp': post.createdAt,
      });
    }
    
    // Добавляем рилсы
    for (final reel in _reels) {
      final timestamp = (reel['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      allItems.add({
        'type': 'reel',
        'data': reel,
        'timestamp': timestamp,
      });
    }
    
    // Сортируем по времени
    allItems.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    for (final item in allItems) {
      if (item['type'] == 'post') {
        items.add(
          SliverToBoxAdapter(
            child: _buildPostCard(item['data'] as Post),
          ),
        );
      } else {
        items.add(
          SliverToBoxAdapter(
            child: _buildReelCard(item['data'] as Map<String, dynamic>),
          ),
        );
      }
      
      // Вставляем рекомендации в конец ленты
      if (items.isNotEmpty && _recommendations.isNotEmpty) {
        debugLog("FEED_RECS_COUNT:${_recommendations.length}");
        items.add(
          SliverToBoxAdapter(
            child: _buildRecommendationsSection(),
          ),
        );
      }
    }
    
    return items;
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(post.authorId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final firstName = userData?['firstName'] as String? ?? '';
                final lastName = userData?['lastName'] as String? ?? '';
                final name = '$firstName $lastName'.trim().isEmpty
                    ? (userData?['name'] as String? ?? 'Пользователь')
                    : '$firstName $lastName'.trim();
                final photoUrl = userData?['photoURL'] as String?;
                final city = userData?['city'] as String?;
                final roles = (userData?['roles'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (roles.isNotEmpty || city != null) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              children: [
                                if (city != null)
                                  Text(
                                    city,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ...roles.take(2).map((role) {
                                  final label = role['label'] as String? ?? '';
                                  return Text(
                                    label,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(post.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Text
            if (post.text.isNotEmpty)
              Text(post.text, style: const TextStyle(fontSize: 14)),
            
            // Photos (до 10)
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPhotoGrid(post.media.take(10).toList()),
            ],
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                // Like button
                StreamBuilder<bool>(
                  stream: _likeService.isLikedStream(
                    contentType: 'posts',
                    contentId: post.id,
                  ),
                  builder: (context, likeSnapshot) {
                    final isLiked = likeSnapshot.data ?? false;
                    return StreamBuilder<int>(
                      stream: _likeService.getLikesCount(
                        contentType: 'posts',
                        contentId: post.id,
                      ),
                      builder: (context, countSnapshot) {
                        final likesCount = countSnapshot.data ?? post.likesCount;
                        return Row(
              children: [
                IconButton(
                  icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : null,
                  ),
                              onPressed: () async {
                                final success = await _likeService.toggleLike(
                                  contentType: 'posts',
                                  contentId: post.id,
                                );
                                if (success) {
                                  debugLog("POST_LIKE:${post.id}");
                                  _analyticsService.logPostLike(post.id, post.authorId);
                                }
                  },
                ),
                            Text('$likesCount'),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Comment button
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    _showCommentsBottomSheet(context, 'posts', post.id);
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('comments')
                      .doc('posts')
                      .collection(post.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : post.commentsCount;
                    return Text('$count');
                  },
                ),
                const SizedBox(width: 16),
                // Save button
                StreamBuilder<bool>(
                  stream: _saveService.isSavedStream(
                    contentType: 'posts',
                    contentId: post.id,
                  ),
                  builder: (context, saveSnapshot) {
                    final isSaved = saveSnapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? Colors.blue : null,
                      ),
                      onPressed: () {
                        _saveService.toggleSave(
                          contentType: 'posts',
                          contentId: post.id,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Share button
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    Share.share(
                      'Посмотрите этот пост: ${post.text.isNotEmpty ? post.text : "Без текста"}',
                      subject: 'Пост из Event Marketplace',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelCard(Map<String, dynamic> reel) {
    final posterUrl = reel['posterUrl'] as String?;
    final videoUrl = reel['videoUrl'] as String?;
    final authorId = reel['authorId'] as String?;
    final createdAt = (reel['createdAt'] as Timestamp?)?.toDate();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video/Poster
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (posterUrl != null && posterUrl.isNotEmpty)
                  Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.play_circle_outline, size: 48),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.play_circle_outline, size: 48),
                  ),
                const Center(
                  child: Icon(Icons.play_circle_filled, size: 64, color: Colors.white70),
                ),
              ],
            ),
          ),
          
          // Author info
          if (authorId != null)
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(authorId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final firstName = userData?['firstName'] as String? ?? '';
                final lastName = userData?['lastName'] as String? ?? '';
                final name = '$firstName $lastName'.trim().isEmpty
                    ? (userData?['name'] as String? ?? 'Пользователь')
                    : '$firstName $lastName'.trim();
                final photoUrl = userData?['photoURL'] as String?;
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                _formatTime(createdAt),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () {
                          // TODO: Play video
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    if (photos.length == 1) {
      return Image.network(
        photos[0],
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length > 10 ? 10 : photos.length,
      itemBuilder: (context, index) {
        return Image.network(
          photos[index],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      },
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Рекомендации',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final user = _recommendations[index];
              return _buildRecommendationCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(AppUser user) {
    final userName = '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim().isEmpty
        ? (user.email ?? user.name ?? 'Пользователь')
        : '${user.firstName ?? ""} ${user.lastName ?? ""}'.trim();
    
    return GestureDetector(
      onTap: () => context.push('/profile/${user.uid}'),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: user.photoURL != null && user.photoURL!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(user.photoURL!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: user.photoURL == null || user.photoURL!.isEmpty
                        ? Colors.grey[300]
                        : null,
                  ),
                  child: user.photoURL == null || user.photoURL!.isEmpty
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.city != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.city!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    StreamBuilder<DocumentSnapshot?>(
                      stream: _currentUserId != null
                          ? _firestore
                              .collection('follows')
                              .doc('${_currentUserId}_${user.uid}')
                              .snapshots()
                          : Stream.value(null),
                      builder: (context, followSnapshot) {
                        final isFollowing = followSnapshot.hasData && followSnapshot.data?.exists == true;
                        return ElevatedButton(
                          onPressed: () async {
                            if (isFollowing) {
                              await _followService.unfollowUser(user.uid);
                            } else {
                              await _followService.followUser(user.uid);
                              _analyticsService.logFollowUser(user.uid);
                            }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                          child: Text(isFollowing ? 'Отписаться' : 'Подписаться'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Подпишитесь на специалистов, чтобы видеть посты',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateContentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Пост'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/post');
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Рилс'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/reel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle),
              title: const Text('Сторис'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create/story');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, String parentType, String parentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Комментарии',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CommentListWidget(
                parentType: parentType,
                parentId: parentId,
              ),
            ),
            AddCommentField(
              parentType: parentType,
              parentId: parentId,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'только что';
    }
  }
}


