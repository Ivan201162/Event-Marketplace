import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/priority_service.dart';

class AdvertisementWidget extends StatelessWidget {
  final Advertisement advertisement;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const AdvertisementWidget(
      {super.key, required this.advertisement, this.onTap, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с кнопкой закрытия
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Реклама',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  const Spacer(),
                  if (onClose != null)
                    GestureDetector(
                      onTap: onClose,
                      child:
                          const Icon(Icons.close, color: Colors.grey, size: 16),
                    ),
                ],
              ),
            ),

            // Контент рекламы
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    if (advertisement.title != null) ...[
                      Text(
                        advertisement.title!,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Описание
                    if (advertisement.description != null) ...[
                      Text(
                        advertisement.description!,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Изображение
                    if (advertisement.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          advertisement.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image,
                                  color: Colors.grey, size: 48),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Видео
                    if (advertisement.videoUrl != null) ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.play_circle_filled,
                                color: Colors.white, size: 64),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Видео',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Кнопка действия
                    if (advertisement.targetUrl != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Подробнее',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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

class AdvertisementBannerWidget extends StatelessWidget {
  final Advertisement advertisement;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const AdvertisementBannerWidget({
    super.key,
    required this.advertisement,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                // Контент
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Иконка
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign,
                            color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 12),

                      // Текст
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              advertisement.title ?? 'Реклама',
                              style: Theme.of(
                                context,
                              )
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (advertisement.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                advertisement.description!,
                                style: Theme.of(
                                  context,
                                )
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Стрелка
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.blue, size: 16),
                    ],
                  ),
                ),

                // Кнопка закрытия
                if (onClose != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdvertisementListWidget extends StatefulWidget {
  final AdPlacement placement;
  final String? region;
  final String? city;
  final String? category;
  final int limit;
  final VoidCallback? onAdTap;
  final VoidCallback? onAdClose;

  const AdvertisementListWidget({
    super.key,
    required this.placement,
    this.region,
    this.city,
    this.category,
    this.limit = 3,
    this.onAdTap,
    this.onAdClose,
  });

  @override
  State<AdvertisementListWidget> createState() =>
      _AdvertisementListWidgetState();
}

class _AdvertisementListWidgetState extends State<AdvertisementListWidget> {
  final PriorityService _priorityService = PriorityService();
  List<Advertisement> _advertisements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> _loadAdvertisements() async {
    try {
      final ads = await _priorityService.getAdvertisementsForDisplay(
        placement: widget.placement,
        region: widget.region,
        city: widget.city,
        category: widget.category,
        limit: widget.limit,
      );

      setState(() {
        _advertisements = ads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_advertisements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _advertisements.map((ad) {
        if (widget.placement == AdPlacement.topBanner ||
            widget.placement == AdPlacement.bottomBanner) {
          return AdvertisementBannerWidget(
            advertisement: ad,
            onTap: () {
              widget.onAdTap?.call();
              _trackAdClick(ad);
            },
            onClose: widget.onAdClose,
          );
        } else {
          return AdvertisementWidget(
            advertisement: ad,
            onTap: () {
              widget.onAdTap?.call();
              _trackAdClick(ad);
            },
            onClose: widget.onAdClose,
          );
        }
      }).toList(),
    );
  }

  void _trackAdClick(Advertisement advertisement) {
    // TODO: Отслеживание клика по рекламе
    _priorityService.updateDisplayStats(
      userId: 'current_user', // TODO: Получить ID текущего пользователя
      type: 'advertisement',
      itemId: advertisement.id,
      isClick: true,
    );
  }
}
