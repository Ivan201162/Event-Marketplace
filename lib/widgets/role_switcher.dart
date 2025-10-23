import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../providers/user_role_provider.dart';

class RoleSwitcher extends ConsumerWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(userRoleProvider);
    final roleString =
        currentRole == UserRole.customer ? 'Клиент' : 'Специалист';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Текущая роль: $roleString',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentRole == UserRole.customer
                        ? null
                        : () => ref
                            .read(userRoleProvider.notifier)
                            .setRole(UserRole.customer),
                    icon: const Icon(Icons.person),
                    label: const Text('Клиент'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentRole == UserRole.customer
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: currentRole == UserRole.customer
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentRole == UserRole.specialist
                        ? null
                        : () => ref
                            .read(userRoleProvider.notifier)
                            .setRole(UserRole.specialist),
                    icon: const Icon(Icons.work),
                    label: const Text('Специалист'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentRole == UserRole.specialist
                          ? Colors.green
                          : Colors.grey[300],
                      foregroundColor: currentRole == UserRole.specialist
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentRole == UserRole.customer
                  ? 'Вы можете просматривать свои заявки и создавать новые бронирования'
                  : 'Вы можете управлять заявками клиентов и просматривать свой календарь',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
