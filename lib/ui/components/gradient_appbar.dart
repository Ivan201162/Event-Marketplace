/// GradientAppBar - V7.6 Premium UI
/// Премиум AppBar с градиентом и иконкой настроек

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:event_marketplace_app/theme/colors.dart';
import 'package:event_marketplace_app/theme/typography.dart';
import 'package:event_marketplace_app/services/feedback_service.dart';
import 'package:event_marketplace_app/utils/debug_log.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showSettings;
  final Widget? leading;
  
  const GradientAppBar({
    Key? key,
    this.title,
    this.actions,
    this.showSettings = true,
    this.leading,
  }) : super(key: key);
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.gradientStart.withOpacity(0.9),
            colors.gradientEnd.withOpacity(0.9),
          ],
        ),
      ),
      child: AppBar(
        leading: leading,
        title: title != null ? Text(
          title!,
          style: AppTypography.titleLarge(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ) : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                FeedbackService().hapticLight();
                FeedbackService().soundTap();
                debugLog('NAV:SETTINGS_OPENED');
                context.push('/settings');
              },
            ),
          ...?actions,
        ],
      ),
    );
  }
}

