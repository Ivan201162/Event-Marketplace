import 'package:event_marketplace_app/utils/responsive_utils.dart';
import 'package:event_marketplace_app/widgets/responsive/responsive_widgets.dart';
import 'package:flutter/material.dart';

/// Адаптивный экран чатов
class ResponsiveChatScreen extends StatelessWidget {
  const ResponsiveChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const ResponsiveAppBar(
        title: 'Чаты',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.add_circle_outline),
          ResponsiveSpacing(width: 16),
        ],
      ),
      body: ResponsiveLayoutBuilder(
        mobile: _buildMobileLayout,
        tablet: _buildTabletLayout,
        desktop: _buildDesktopLayout,
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ResponsiveList(
      children: [
        _buildSearchSection(context),
        _buildChatsSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 2,
        children: [
          _buildSearchSection(context),
          _buildChatsSection(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        crossAxisCount: 3,
        children: [
          _buildSearchSection(context),
          _buildChatsSection(context),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Поиск чатов',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Поиск по имени или сообщению',
              prefixIcon: const ResponsiveIcon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsSection(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Чаты',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22,),
              fontWeight: FontWeight.bold,
            ),
          ),
          const ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildChatItem(context, 'Анна Петрова',
                  'Спасибо за отличную работу!', '2 часа назад', true, 2,),
              _buildChatItem(context, 'Иван Сидоров',
                  'Когда можем встретиться?', '4 часа назад', false, 0,),
              _buildChatItem(context, 'Мария Козлова', 'Договорились на завтра',
                  '1 день назад', false, 0,),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, String name, String lastMessage,
      String time, bool isUnread, int unreadCount,) {
    return ResponsiveCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.getResponsiveIconSize(context,
                mobile: 20, tablet: 24, desktop: 28,),
            backgroundColor: isUnread ? Colors.blue : Colors.grey,
            child: ResponsiveText(
              name[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,),
              ),
            ),
          ),
          const ResponsiveSpacing(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        name,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,),
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    ResponsiveText(
                      time,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context,
                            mobile: 12, tablet: 14, desktop: 16,),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const ResponsiveSpacing(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        lastMessage,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,),
                          color: isUnread ? Colors.black : Colors.grey[600],
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread && unreadCount > 0)
                      ResponsiveCard(
                        child: ResponsiveText(
                          '$unreadCount',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobile: 10,
                                tablet: 12,
                                desktop: 14,),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
