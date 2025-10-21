import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/specialist.dart';
import '../providers/search_providers.dart';
import '../repositories/chats_repository.dart';

/// Анимированная карусель лучших специалистов
class AnimatedSpecialistsCarousel extends ConsumerStatefulWidget {
  const AnimatedSpecialistsCarousel({super.key});

  @override
  ConsumerState<AnimatedSpecialistsCarousel> createState() => _AnimatedSpecialistsCarouselState();
}

class _AnimatedSpecialistsCarouselState extends ConsumerState<AnimatedSpecialistsCarousel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Создаем анимации для карточек
    _cardControllers = List.generate(
      5, // Максимум 5 карточек
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    _cardSlideAnimations = _cardControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    _animationController.forward();
    _startCardAnimations();
  }

  void _startCardAnimations() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialistsAsync = ref.watch(allSpecialistsProvider);

    return specialistsAsync.when(
      data: (specialists) {
        // Берем топ-5 специалистов по рейтингу
        final topSpecialists = specialists..sort((a, b) => b.rating.compareTo(a.rating));
        final top5 = topSpecialists.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Лучшие специалисты недели',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(onPressed: () => context.push('/search'), child: const Text('Все')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: top5.length,
                itemBuilder: (context, index) {
                  final specialist = top5[index];
                  return AnimatedBuilder(
                    animation: _cardAnimations[index],
                    builder: (context, child) {
                      return SlideTransition(
                        position: _cardSlideAnimations[index],
                        child: FadeTransition(
                          opacity: _cardAnimations[index],
                          child: _SpecialistCard(specialist: specialist),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Ошибка загрузки специалистов')),
    );
  }
}

/// Анимированная карточка специалиста
class _SpecialistCard extends StatefulWidget {
  const _SpecialistCard({required this.specialist});
  final Specialist specialist;

  @override
  State<_SpecialistCard> createState() => _SpecialistCardState();
}

class _SpecialistCardState extends State<_SpecialistCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child:             Container(
              width: 180,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => context.push('/specialist/${widget.specialist.id}'),
                onTapDown: (_) {
                  setState(() => _isHovered = true);
                  _hoverController.forward();
                },
                onTapUp: (_) {
                  setState(() => _isHovered = false);
                  _hoverController.reverse();
                },
                onTapCancel: () {
                  setState(() => _isHovered = false);
                  _hoverController.reverse();
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Улучшенный аватар специалиста
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: widget.specialist.avatar != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(widget.specialist.avatar!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        gradient: widget.specialist.avatar == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor.withOpacity(0.1),
                                  Theme.of(context).primaryColor.withOpacity(0.05),
                                ],
                              )
                            : null,
                      ),
                      child: widget.specialist.avatar == null
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                // Градиентный оверлей
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ),
                                // Рейтинг в углу
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: Colors.amber[600], size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          widget.specialist.rating.toString(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    // Информация о специалисте
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.specialist.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.specialist.category?.displayName ?? 'Категория',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            // Цена с улучшенным дизайном
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor.withOpacity(0.1),
                                    Theme.of(context).primaryColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'от ${widget.specialist.price}₸',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Улучшенные кнопки действий
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context).primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _openChat(context),
                                        borderRadius: BorderRadius.circular(16),
                                        child: const Center(
                                          child: Text(
                                            'Связаться',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.green, Color(0xFF4CAF50)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _openBooking(context),
                                        borderRadius: BorderRadius.circular(16),
                                        child: const Center(
                                          child: Text(
                                            'Забронировать',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
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
            ),
          );
        },
      );

  /// Открыть чат с специалистом
  Future<void> _openChat(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Необходимо войти в аккаунт')));
        return;
      }

      final chatsRepository = ChatsRepository();
      final chatId = await chatsRepository.findOrCreateChat(currentUser.uid, widget.specialist.id);

      if (chatId != null) {
        context.push('/chat/$chatId');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка создания чата')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  /// Открыть форму бронирования
  void _openBooking(BuildContext context) {
    context.push('/booking/${widget.specialist.id}');
  }
}
