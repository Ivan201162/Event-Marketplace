import 'package:flutter/material.dart';

/// UI Kit для состояний загрузки
class UILoading {
  /// Основной индикатор загрузки
  static Widget primary({
    double size = 24,
    Color? color,
    double strokeWidth = 2,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.blue,
        ),
      ),
    );
  }

  /// Линейный индикатор загрузки
  static Widget linear({
    double height = 4,
    Color? backgroundColor,
    Color? valueColor,
    double? value,
  }) {
    return LinearProgressIndicator(
      minHeight: height,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(
        valueColor ?? Colors.blue,
      ),
      value: value,
    );
  }

  /// Skeleton загрузка для текста
  static Widget textSkeleton({
    double width = double.infinity,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }

  /// Skeleton загрузка для карточки
  static Widget cardSkeleton({
    double width = double.infinity,
    double height = 200,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }

  /// Skeleton загрузка для аватара
  static Widget avatarSkeleton({
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  /// Skeleton загрузка для списка
  static Widget listSkeleton({
    int itemCount = 5,
    double itemHeight = 80,
    double spacing = 8,
  }) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  /// Skeleton загрузка для сетки
  static Widget gridSkeleton({
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double spacing = 8,
    int itemCount = 6,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  /// Shimmer эффект
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor ?? Colors.grey[300]!,
            highlightColor ?? Colors.grey[100]!,
            baseColor ?? Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }

  /// Полноэкранная загрузка
  static Widget fullScreen({
    String? message,
    Color? backgroundColor,
    Color? textColor,
    double size = 48,
  }) {
    return Container(
      color: backgroundColor ?? Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.blue,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Загрузка с кнопкой отмены
  static Widget cancellable({
    required VoidCallback onCancel,
    String? message,
    String cancelText = 'Отмена',
    Color? backgroundColor,
    Color? textColor,
    double size = 48,
  }) {
    return Container(
      color: backgroundColor ?? Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.blue,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: Text(cancelText),
            ),
          ],
        ),
      ),
    );
  }

  /// Загрузка с прогрессом
  static Widget withProgress({
    required double progress,
    String? message,
    Color? backgroundColor,
    Color? textColor,
    Color? progressColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message != null) ...[
              Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: textColor ?? Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Загрузка с анимацией
  static Widget animated({
    String? message,
    Color? backgroundColor,
    Color? textColor,
    double size = 48,
  }) {
    return Container(
      color: backgroundColor ?? Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Icon(
                    Icons.refresh,
                    size: size,
                    color: textColor ?? Colors.blue,
                  ),
                );
              },
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Расширение для BuildContext для удобного доступа к загрузке
extension UILoadingExtension on BuildContext {
  Widget primaryLoading({
    double size = 24,
    Color? color,
    double strokeWidth = 2,
  }) {
    return UILoading.primary(
      size: size,
      color: color,
      strokeWidth: strokeWidth,
    );
  }

  Widget linearLoading({
    double height = 4,
    Color? backgroundColor,
    Color? valueColor,
    double? value,
  }) {
    return UILoading.linear(
      height: height,
      backgroundColor: backgroundColor,
      valueColor: valueColor,
      value: value,
    );
  }

  Widget textSkeleton({
    double width = double.infinity,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    return UILoading.textSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  Widget cardSkeleton({
    double width = double.infinity,
    double height = 200,
    BorderRadius? borderRadius,
  }) {
    return UILoading.cardSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  Widget avatarSkeleton({
    double size = 40,
  }) {
    return UILoading.avatarSkeleton(size: size);
  }

  Widget listSkeleton({
    int itemCount = 5,
    double itemHeight = 80,
    double spacing = 8,
  }) {
    return UILoading.listSkeleton(
      itemCount: itemCount,
      itemHeight: itemHeight,
      spacing: spacing,
    );
  }

  Widget gridSkeleton({
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double spacing = 8,
    int itemCount = 6,
  }) {
    return UILoading.gridSkeleton(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      spacing: spacing,
      itemCount: itemCount,
    );
  }

  Widget fullScreenLoading({
    String? message,
    Color? backgroundColor,
    Color? textColor,
    double size = 48,
  }) {
    return UILoading.fullScreen(
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      size: size,
    );
  }
}
