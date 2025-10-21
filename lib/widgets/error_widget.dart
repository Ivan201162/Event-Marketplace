import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ],
    ),
  );
}
