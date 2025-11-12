/// LoadingSkeleton - V7.6 Premium UI
/// Скелет-лоадер для загрузочных состояний

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const LoadingSkeleton({
    Key? key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface,
      highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SpecialistCardSkeleton extends StatelessWidget {
  const SpecialistCardSkeleton({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const LoadingSkeleton(width: 60, height: 60, borderRadius: BorderRadius.all(Radius.circular(30))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeleton(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const LoadingSkeleton(width: 100, height: 12),
                const SizedBox(height: 8),
                const LoadingSkeleton(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

