import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_role_provider.dart';
import '../providers/firestore_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Профиль")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Текущая роль: ${role == UserRole.customer ? "Заказчик" : "Специалист"}"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(userRoleProvider.notifier).state =
                    role == UserRole.customer ? UserRole.specialist : UserRole.customer;
              },
              child: const Text("Переключить роль"),
            ),
            const SizedBox(height: 24),
            const Text("Тестовые данные:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(firestoreServiceProvider).addTestBookings();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Тестовые заявки добавлены')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              child: const Text('Добавить тестовые заявки'),
            ),
          ],
        ),
      ),
    );
  }
}
