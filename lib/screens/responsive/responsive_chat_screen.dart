import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive/responsive_widgets.dart';

/// Адаптивный экран чатов
class ResponsiveChatScreen extends StatelessWidget {
  const ResponsiveChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: ResponsiveAppBar(
        title: 'Чаты',
        actions: [
          ResponsiveIcon(Icons.search),
          ResponsiveSpacing(width: 8),
          ResponsiveIcon(Icons.add_circle_outline),
          ResponsiveSpacing(width: 16),
        ],
      ),
      body: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
        desktop: (context) => _buildDesktopLayout(context),
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
        children: [
          _buildSearchSection(context),
          _buildChatsSection(context),
        ],
        crossAxisCount: 2,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGrid(
        children: [
          _buildSearchSection(context),
          _buildChatsSection(context),
        ],
        crossAxisCount: 3,
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Поиск по имени или сообщению',
              prefixIcon: ResponsiveIcon(Icons.search),
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
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveList(
            children: [
              _buildChatItem(context, 'Анна Петрова', 'Спасибо за отличную работу!', '2 часа назад', true, 2),
              _buildChatItem(context, 'Иван Сидоров', 'Когда можем встретиться?', '4 часа назад', false, 0),
              _buildChatItem(context, 'Мария Козлова', 'Договорились на завтра', '1 день назад', false, 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, String name, String lastMessage, String time, bool isUnread, int unreadCount) {
    return ResponsiveCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
            backgroundColor: isUnread ? Colors.blue : Colors.grey,
            child: ResponsiveText(
              name[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
              ),
            ),
          ),
          ResponsiveSpacing(width: 16),
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
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    ResponsiveText(
                      time,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ResponsiveSpacing(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        lastMessage,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                          color: isUnread ? Colors.black : Colors.grey[600],
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
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
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
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
