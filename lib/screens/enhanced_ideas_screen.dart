import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_idea.dart';
import '../providers/enhanced_ideas_providers.dart';

class EnhancedIdeasScreen extends ConsumerStatefulWidget {
  const EnhancedIdeasScreen({super.key});

  @override
  ConsumerState<EnhancedIdeasScreen> createState() =>
      _EnhancedIdeasScreenState();
}

class _EnhancedIdeasScreenState extends ConsumerState<EnhancedIdeasScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ideasNotifier = ref.watch(enhancedIdeasProvider);
    final ideasState = ideasNotifier.state;

    return Column(
      children: [
        // TabBar для переключения между фото и видео
        Container(
          color: Theme.of(context).primaryColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.photo_library),
                text: 'Фото',
              ),
              Tab(
                icon: Icon(Icons.video_library),
                text: 'Видео',
              ),
            ],
          ),
        ),
        // Контент с TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PhotoIdeasTab(ideasState: ideasState),
              _VideoIdeasTab(ideasState: ideasState),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoIdeasTab extends ConsumerWidget {

  const _PhotoIdeasTab({required this.ideasState});
  final EnhancedIdeasState ideasState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoIdeas =
        ideasState.ideas.where((idea) => idea.type == 'image').toList();

    if (ideasState.isLoading && photoIdeas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (photoIdeas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет фото идей',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Добавьте свои идеи для вдохновения',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(enhancedIdeasProvider).refreshIdeas(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: photoIdeas.length,
        itemBuilder: (context, index) {
          final idea = photoIdeas[index];
          return _PhotoIdeaCard(idea: idea);
        },
      ),
    );
  }
}

class _VideoIdeasTab extends ConsumerWidget {

  const _VideoIdeasTab({required this.ideasState});
  final EnhancedIdeasState ideasState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoIdeas =
        ideasState.ideas.where((idea) => idea.type == 'video').toList();

    if (ideasState.isLoading && videoIdeas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (videoIdeas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет видео идей',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Добавьте свои видео идеи',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(enhancedIdeasProvider).refreshIdeas(),
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videoIdeas.length,
        itemBuilder: (context, index) {
          final idea = videoIdeas[index];
          return _VideoIdeaCard(idea: idea);
        },
      ),
    );
  }
}

class _PhotoIdeaCard extends ConsumerWidget {

  const _PhotoIdeaCard({required this.idea});
  final EnhancedIdea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasNotifier = ref.read(enhancedIdeasProvider);

    return InkWell(
      onTap: () => context.push('/idea/${idea.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение идеи
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: idea.media.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: idea.media.first.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 40),
                        ),
                      ),
              ),
            ),
            // Информация об идее
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.authorName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: idea.isLiked ? Colors.red : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.likes}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.comment,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.comments}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        if (idea.budget != null)
                          Text(
                            '${idea.budget}₸',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoIdeaCard extends ConsumerWidget {

  const _VideoIdeaCard({required this.idea});
  final EnhancedIdea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasNotifier = ref.read(enhancedIdeasProvider);

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Видео контент
          if (idea.media.isNotEmpty)
            Center(
              child: CachedNetworkImage(
                imageUrl: idea.media.first.thumbnail ?? idea.media.first.url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.white),
                  ),
                ),
              ),
            ),

          // Кнопка воспроизведения
          const Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 80,
              color: Colors.white,
            ),
          ),

          // Информация об идее
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    idea.authorName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => ideasNotifier.toggleLike(idea.id),
                        icon: Icon(
                          idea.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: idea.isLiked ? Colors.red : Colors.white,
                        ),
                      ),
                      Text(
                        '${idea.likes}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          // Открыть комментарии
                        },
                        icon: const Icon(
                          Icons.comment,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${idea.comments}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => ideasNotifier.toggleSave(idea.id),
                        icon: Icon(
                          idea.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: idea.isSaved ? Colors.amber : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
