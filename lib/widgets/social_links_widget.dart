import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/social_link.dart';

/// Виджет социальных ссылок специалиста
class SocialLinksWidget extends StatelessWidget {
  const SocialLinksWidget({
    super.key,
    required this.socialLinks,
    this.onLinkTap,
  });

  final List<SocialLink> socialLinks;
  final Function(SocialLink)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    if (socialLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Социальные сети',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${socialLinks.length} ссылок',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Список социальных ссылок
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: socialLinks.map((link) => _buildSocialLink(link)).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialLink(SocialLink link) {
    return GestureDetector(
      onTap: () => _handleLinkTap(link),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getPlatformColor(link.platform).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getPlatformColor(link.platform).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              link.platform.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPlatformName(link.platform),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getPlatformColor(link.platform),
                  ),
                ),
                if (link.username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${link.username}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (link.followersCount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_formatFollowers(link.followersCount!)} подписчиков',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
            if (link.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.verified,
                color: Colors.blue,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPlatformName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.vk:
        return 'VKontakte';
      case SocialPlatform.telegram:
        return 'Telegram';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.website:
        return 'Сайт';
    }
  }

  Color _getPlatformColor(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return const Color(0xFFE4405F);
      case SocialPlatform.vk:
        return const Color(0xFF0077FF);
      case SocialPlatform.telegram:
        return const Color(0xFF0088CC);
      case SocialPlatform.youtube:
        return const Color(0xFFFF0000);
      case SocialPlatform.tiktok:
        return const Color(0xFF000000);
      case SocialPlatform.facebook:
        return const Color(0xFF1877F2);
      case SocialPlatform.twitter:
        return const Color(0xFF1DA1F2);
      case SocialPlatform.linkedin:
        return const Color(0xFF0077B5);
      case SocialPlatform.website:
        return const Color(0xFF6B7280);
    }
  }

  String _formatFollowers(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  Future<void> _handleLinkTap(SocialLink link) async {
    onLinkTap?.call(link);
    
    try {
      final uri = Uri.parse(link.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Ошибка открытия ссылки: $e');
    }
  }
}

