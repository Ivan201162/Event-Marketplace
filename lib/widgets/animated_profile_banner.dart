import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/social_models.dart';
import '../services/supabase_service.dart';

class AnimatedProfileBanner extends StatefulWidget {
  final ScrollController scrollController;
  final Profile? profile;

  const AnimatedProfileBanner({
    super.key,
    required this.scrollController,
    this.profile,
  });

  @override
  State<AnimatedProfileBanner> createState() => _AnimatedProfileBannerState();
}

class _AnimatedProfileBannerState extends State<AnimatedProfileBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentPosition = widget.scrollController.position.pixels;
    final delta = currentPosition - _lastScrollPosition;
    
    // Показываем/скрываем в зависимости от направления скролла
    if (delta > 10 && _isVisible) {
      // Скролл вниз - скрываем
      setState(() {
        _isVisible = false;
      });
      _animationController.forward();
    } else if (delta < -10 && !_isVisible) {
      // Скролл вверх - показываем
      setState(() {
        _isVisible = true;
      });
      _animationController.reverse();
    }
    
    _lastScrollPosition = currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              height: 100,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Аватар
                    GestureDetector(
                      onTap: () {
                        // Переход в профиль
                        Navigator.pushNamed(
                          context,
                          '/profile/${widget.profile!.username}',
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: widget.profile!.avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.profile!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: Theme.of(context).primaryColor,
                                      size: 30,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: Theme.of(context).primaryColor,
                                      size: 30,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(context).primaryColor,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Информация о пользователе
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Имя
                          Text(
                            widget.profile!.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Город и статус
                          Row(
                            children: [
                              if (widget.profile!.city != null) ...[
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.profile!.city!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Статус
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Активен',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Кнопка редактирования профиля
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile/me');
                      },
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Редактировать профиль',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

