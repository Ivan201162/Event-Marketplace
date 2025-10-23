import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Анимированный блок "Интересное"
class AnimatedInterestingSection extends StatefulWidget {
  const AnimatedInterestingSection({super.key});

  @override
  State<AnimatedInterestingSection> createState() =>
      _AnimatedInterestingSectionState();
}

class _AnimatedInterestingSectionState extends State<AnimatedInterestingSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Создаем анимации для карточек
    _cardControllers = List.generate(
      3, // 3 карточки
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    _cardSlideAnimations = _cardControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    }).toList();

    _animationController.forward();
    _startCardAnimations();
  }

  void _startCardAnimations() {
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
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
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Интересное',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _cardAnimations[0],
                  builder: (context, child) {
                    return SlideTransition(
                      position: _cardSlideAnimations[0],
                      child: FadeTransition(
                        opacity: _cardAnimations[0],
                        child: _InterestingCard(
                          title: 'Самые популярные категории недели',
                          icon: Icons.trending_up,
                          color: Colors.orange,
                          onTap: () => context.push('/search?sort=popular'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: _cardAnimations[1],
                  builder: (context, child) {
                    return SlideTransition(
                      position: _cardSlideAnimations[1],
                      child: FadeTransition(
                        opacity: _cardAnimations[1],
                        child: _InterestingCard(
                          title: 'Новые специалисты',
                          icon: Icons.person_add,
                          color: Colors.green,
                          onTap: () => context.push('/search?sort=newest'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _cardAnimations[2],
            builder: (context, child) {
              return SlideTransition(
                position: _cardSlideAnimations[2],
                child: FadeTransition(
                  opacity: _cardAnimations[2],
                  child: _InterestingCard(
                    title: 'Специалисты рядом',
                    icon: Icons.location_on,
                    color: Colors.blue,
                    onTap: () => context.push('/search?nearby=true'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Анимированная карточка интересного контента
class _InterestingCard extends StatefulWidget {
  const _InterestingCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_InterestingCard> createState() => _InterestingCardState();
}

class _InterestingCardState extends State<_InterestingCard>
    with SingleTickerProviderStateMixin {
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
    ).animate(
        CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut));
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
            child: InkWell(
              onTap: widget.onTap,
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      widget.color.withValues(alpha: _isHovered ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        widget.color.withValues(alpha: _isHovered ? 0.4 : 0.3),
                    width: _isHovered ? 2 : 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: _isHovered ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(widget.icon, color: widget.color, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight:
                            _isHovered ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
