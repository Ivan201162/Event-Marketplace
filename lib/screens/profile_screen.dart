import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/modern_profile_screen.dart';

/// Основной экран профиля в стиле Instagram/VK
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });
  final String userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModernProfileScreen(
        userId: userId,
        isOwnProfile: isOwnProfile,
      );
}
