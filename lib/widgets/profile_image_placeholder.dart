import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Виджет для отображения placeholder'а профильного фото
class ProfileImagePlaceholder extends StatelessWidget {
  const ProfileImagePlaceholder({
    super.key,
    this.size = 60,
    this.name,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.border,
    this.showBorder = true,
  });

  final double size;
  final String? name;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final effectiveTextColor = textColor ?? theme.colorScheme.onPrimaryContainer;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(size / 2);

    // Получаем инициалы из имени
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: showBorder
            ? (border ?? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)))
            : null,
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(Icons.person, color: effectiveTextColor, size: size * 0.5),
      ),
    );
  }

  /// Получить инициалы из имени
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return '';
    }

    final words = name.trim().split(' ');
    if (words.isEmpty) {
      return '';
    }

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }
}

/// Виджет для отображения аватара с возможностью загрузки изображения
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 60,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.border,
    this.showBorder = true,
    this.onTap,
    this.placeholder,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;
  final VoidCallback? onTap;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(size / 2);

    Widget avatarWidget;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Показываем изображение с кэшированием
      avatarWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            border: showBorder
                ? (border ?? Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)))
                : null,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => ProfileImagePlaceholder(
          size: size,
          name: name,
          backgroundColor: backgroundColor,
          textColor: textColor,
          borderRadius: effectiveBorderRadius,
          border: border,
          showBorder: showBorder,
        ),
        errorWidget: (context, url, error) => ProfileImagePlaceholder(
          size: size,
          name: name,
          backgroundColor: backgroundColor,
          textColor: textColor,
          borderRadius: effectiveBorderRadius,
          border: border,
          showBorder: showBorder,
        ),
      );
    } else {
      // Показываем placeholder
      avatarWidget = placeholder ??
          ProfileImagePlaceholder(
            size: size,
            name: name,
            backgroundColor: backgroundColor,
            textColor: textColor,
            borderRadius: effectiveBorderRadius,
            border: border,
            showBorder: showBorder,
          );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarWidget);
    }

    return avatarWidget;
  }
}

/// Виджет для отображения группы аватаров
class AvatarGroup extends StatelessWidget {
  const AvatarGroup({
    super.key,
    required this.avatars,
    this.maxVisible = 3,
    this.size = 40,
    this.spacing = -8,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.border,
    this.showBorder = true,
  });

  final List<AvatarData> avatars;
  final int maxVisible;
  final double size;
  final double spacing;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatars.take(maxVisible).toList();
    final remainingCount = avatars.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleAvatars.asMap().entries.map((entry) {
          final index = entry.key;
          final avatar = entry.value;

          return Container(
            margin: EdgeInsets.only(left: index > 0 ? spacing : 0),
            child: ProfileAvatar(
              imageUrl: avatar.imageUrl,
              name: avatar.name,
              size: size,
              backgroundColor: backgroundColor,
              textColor: textColor,
              borderRadius: borderRadius,
              border: border,
              showBorder: showBorder,
            ),
          );
        }),
        if (remainingCount > 0)
          Container(
            margin: EdgeInsets.only(left: spacing),
            child: ProfileImagePlaceholder(
              size: size,
              name: '+$remainingCount',
              backgroundColor: backgroundColor,
              textColor: textColor,
              borderRadius: borderRadius,
              border: border,
              showBorder: showBorder,
            ),
          ),
      ],
    );
  }
}

/// Данные для аватара
class AvatarData {
  const AvatarData({this.imageUrl, this.name});

  final String? imageUrl;
  final String? name;
}

/// Виджет для отображения аватара с индикатором статуса
class StatusAvatar extends StatelessWidget {
  const StatusAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 60,
    this.status = AvatarStatus.offline,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.border,
    this.showBorder = true,
    this.onTap,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final AvatarStatus status;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool showBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(status, theme);
    final statusSize = size * 0.25;

    return Stack(
      children: [
        ProfileAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          backgroundColor: backgroundColor,
          textColor: textColor,
          borderRadius: borderRadius,
          border: border,
          showBorder: showBorder,
          onTap: onTap,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: statusSize,
            height: statusSize,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AvatarStatus status, ThemeData theme) {
    switch (status) {
      case AvatarStatus.online:
        return Colors.green;
      case AvatarStatus.away:
        return Colors.orange;
      case AvatarStatus.busy:
        return Colors.red;
      case AvatarStatus.offline:
        return Colors.grey;
    }
  }
}

/// Статусы аватара
enum AvatarStatus { online, away, busy, offline }
