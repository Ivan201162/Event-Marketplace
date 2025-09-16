import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(() {
  return UserRoleNotifier();
});

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.customer;
  
  void setRole(UserRole role) {
    state = role;
  }
}

// Демонстрационные id для тестового режима (замени на реальные id после аутентификации)
final demoCustomerIdProvider = Provider<String>((ref) => 'u_customer1');
final demoSpecialistIdProvider = Provider<String>((ref) => 's1');
