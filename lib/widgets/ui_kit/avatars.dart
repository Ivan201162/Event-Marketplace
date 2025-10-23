import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// UI Kit для аватаров
class UIAvatars {
  /// Основной аватар
  static Widget primary({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 2,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Colors.grey[300]!,
                  width: borderWidth,
                )
              : null,
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(
                    size: size,
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                    fallbackText: fallbackText,
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholder(
                    size: size,
                    backgroundColor: backgroundColor,
                    textColor: textColor,
                    fallbackText: fallbackText,
                  ),
                )
              : _buildPlaceholder(
                  size: size,
                  backgroundColor: backgroundColor,
                  textColor: textColor,
                  fallbackText: fallbackText,
                ),
        ),
      ),
    );
  }

  /// Аватар с индикатором онлайн
  static Widget withOnlineStatus({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    bool isOnline = false,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? onlineColor = Colors.green,
    Color? offlineColor = Colors.grey,
  }) {
    return Stack(
      children: [
        primary(
          imageUrl: imageUrl,
          fallbackText: fallbackText,
          size: size,
          onTap: onTap,
          backgroundColor: backgroundColor,
          textColor: textColor,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: isOnline ? onlineColor : offlineColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Аватар с бейджем
  static Widget withBadge({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    Widget? badge,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? badgeColor = Colors.red,
    String? badgeText,
    int? badgeCount,
  }) {
    return Stack(
      children: [
        primary(
          imageUrl: imageUrl,
          fallbackText: fallbackText,
          size: size,
          onTap: onTap,
          backgroundColor: backgroundColor,
          textColor: textColor,
        ),
        if (badge != null || badgeText != null || badgeCount != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: badge ??
                    Text(
                      badgeText ??
                          (badgeCount != null ? badgeCount.toString() : ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ),
      ],
    );
  }

  /// Аватар с рейтингом
  static Widget withRating({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    double rating = 0,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? ratingColor = Colors.amber,
  }) {
    return Stack(
      children: [
        primary(
          imageUrl: imageUrl,
          fallbackText: fallbackText,
          size: size,
          onTap: onTap,
          backgroundColor: backgroundColor,
          textColor: textColor,
        ),
        if (rating > 0)
          Positioned(
            bottom: -2,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: ratingColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Групповой аватар
  static Widget group({
    required List<String?> imageUrls,
    double size = 40,
    int maxVisible = 3,
    double overlap = 0.3,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final visibleImages = imageUrls.take(maxVisible).toList();
    final remainingCount = imageUrls.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (visibleImages.length - 1) * size * (1 - overlap),
        height: size,
        child: Stack(
          children: [
            ...visibleImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;
              return Positioned(
                left: index * size * (1 - overlap),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildPlaceholder(
                              size: size,
                              backgroundColor: backgroundColor,
                              textColor: textColor,
                            ),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(
                              size: size,
                              backgroundColor: backgroundColor,
                              textColor: textColor,
                            ),
                          )
                        : _buildPlaceholder(
                            size: size,
                            backgroundColor: backgroundColor,
                            textColor: textColor,
                          ),
                  ),
                ),
              );
            }),
            if (remainingCount > 0)
              Positioned(
                left: visibleImages.length * size * (1 - overlap),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Плейсхолдер для аватара
  static Widget _buildPlaceholder({
    required double size,
    Color? backgroundColor,
    Color? textColor,
    String? fallbackText,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: fallbackText != null && fallbackText.isNotEmpty
            ? Text(
                fallbackText.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: textColor ?? Colors.grey[600],
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                Icons.person,
                color: textColor ?? Colors.grey[600],
                size: size * 0.6,
              ),
      ),
    );
  }
}

/// Расширение для BuildContext для удобного доступа к аватарам
extension UIAvatarsExtension on BuildContext {
  Widget primaryAvatar({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    bool showBorder = false,
    Color? borderColor,
    double borderWidth = 2,
  }) {
    return UIAvatars.primary(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: size,
      onTap: onTap,
      backgroundColor: backgroundColor,
      textColor: textColor,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  Widget onlineAvatar({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    bool isOnline = false,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? onlineColor = Colors.green,
    Color? offlineColor = Colors.grey,
  }) {
    return UIAvatars.withOnlineStatus(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: size,
      isOnline: isOnline,
      onTap: onTap,
      backgroundColor: backgroundColor,
      textColor: textColor,
      onlineColor: onlineColor,
      offlineColor: offlineColor,
    );
  }

  Widget badgeAvatar({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    Widget? badge,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? badgeColor = Colors.red,
    String? badgeText,
    int? badgeCount,
  }) {
    return UIAvatars.withBadge(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: size,
      badge: badge,
      onTap: onTap,
      backgroundColor: backgroundColor,
      textColor: textColor,
      badgeColor: badgeColor,
      badgeText: badgeText,
      badgeCount: badgeCount,
    );
  }

  Widget ratingAvatar({
    required String? imageUrl,
    String? fallbackText,
    double size = 40,
    double rating = 0,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? ratingColor = Colors.amber,
  }) {
    return UIAvatars.withRating(
      imageUrl: imageUrl,
      fallbackText: fallbackText,
      size: size,
      rating: rating,
      onTap: onTap,
      backgroundColor: backgroundColor,
      textColor: textColor,
      ratingColor: ratingColor,
    );
  }

  Widget groupAvatar({
    required List<String?> imageUrls,
    double size = 40,
    int maxVisible = 3,
    double overlap = 0.3,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return UIAvatars.group(
      imageUrls: imageUrls,
      size: size,
      maxVisible: maxVisible,
      overlap: overlap,
      onTap: onTap,
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}
