import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final userRoleProvider = StateProvider<UserRole>((ref) => UserRole.customer);

// Демонстрационные id для тестового режима (замени на реальные id после аутентификации)
final demoCustomerIdProvider = Provider<String>((ref) => 'u_customer1');
final demoSpecialistIdProvider = Provider<String>((ref) => 's1');
