import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/typography.dart';

class SplashScreen extends StatelessWidget {
  final bool showRetry;
  const SplashScreen({this.showRetry = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EVENT крупно
            Text(
              "EVENT",
              style: AppTypography.displayLg.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0, duration: 600.ms),
            
            // Разделитель
            Container(
              width: 60,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .scaleX(begin: 0, end: 1, duration: 400.ms),
            
            // Подзаголовок
            Text(
              "Найдите своего идеального специалиста для мероприятий",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),
            
            if (showRetry) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Перезапуск приложения
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                child: const Text("Повторить"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

