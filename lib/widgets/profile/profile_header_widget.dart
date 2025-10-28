import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_marketplace_app/models/user.dart';
import 'package:event_marketplace_app/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Виджет заголовка профиля
class ProfileHeaderWidget extends StatefulWidget {
  const ProfileHeaderWidget(
      {required this.user, required this.isCurrentUser, super.key,});

  final AppUser user;
  final bool isCurrentUser;

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    if (!widget.isCurrentUser) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);

        final imageUploadService = ImageUploadService();
        final downloadUrl = await imageUploadService.uploadUserAvatar(
          File(image.path),
          widget.user.uid,
        );

        // Обновляем профиль пользователя
        // TODO: Добавить обновление профиля через AuthService
        debugPrint('Avatar uploaded: $downloadUrl');
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки аватарки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар с возможностью загрузки
          Stack(
            children: [
              GestureDetector(
                onTap: widget.isCurrentUser ? _pickAndUploadAvatar : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: _isUploading
                      ? SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryColor,),
                          ),
                        )
                      : widget.user.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.user.avatarUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 100,
                                  height: 100,
                                  color:
                                      theme.primaryColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.person,
                                      size: 50, color: theme.primaryColor,),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 100,
                                  height: 100,
                                  color:
                                      theme.primaryColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.person,
                                      size: 50, color: theme.primaryColor,),
                                ),
                              ),
                            )
                          : Icon(Icons.person,
                              size: 50, color: theme.primaryColor,),
                ),
              ),
              if (widget.user.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardColor, width: 2),
                    ),
                    child: const Icon(Icons.verified,
                        color: Colors.white, size: 14,),
                  ),
                ),
              // Кнопка редактирования аватарки
              if (widget.isCurrentUser && !_isUploading)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Имя пользователя
          Text(
            widget.user.displayName ?? widget.user.email.split('@').first,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            widget.user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Роль
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.user.roleDisplayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (widget.user.city != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.user.city!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],

          if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(widget.user.bio!,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center,),
          ],

          // Специализации (для специалистов)
          if (widget.user.isSpecialist &&
              widget.user.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.user.specialties
                  .take(3)
                  .map(
                    (specialty) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
