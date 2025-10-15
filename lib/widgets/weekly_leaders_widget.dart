import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/social_models.dart';
import '../services/supabase_service.dart';

class WeeklyLeadersWidget extends StatefulWidget {
  final String? userCity;

  const WeeklyLeadersWidget({
    super.key,
    this.userCity,
  });

  @override
  State<WeeklyLeadersWidget> createState() => _WeeklyLeadersWidgetState();
}

class _WeeklyLeadersWidgetState extends State<WeeklyLeadersWidget> {
  List<WeeklyLeader> _leaders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaders();
  }

  Future<void> _loadLeaders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final leaders = await SupabaseService.getWeeklyLeaders(
        city: widget.userCity,
        limit: 10,
      );

      setState(() {
        _leaders = leaders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Лучшие специалисты недели',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.userCity != null 
                          ? 'в ${widget.userCity}'
                          : 'по всей России',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadLeaders,
                icon: const Icon(Icons.refresh),
                tooltip: 'Обновить',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Список лидеров
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ошибка загрузки',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadLeaders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (_leaders.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Пока нет данных',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Статистика будет доступна после активности специалистов',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _leaders.length,
                itemBuilder: (context, index) {
                  final leader = _leaders[index];
                  return _buildLeaderCard(leader, index + 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderCard(WeeklyLeader leader, int position) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/profile/${leader.username}',
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Позиция
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getPositionColor(position),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      position.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Аватар
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getPositionColor(position),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: leader.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: leader.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: _getPositionColor(position).withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: _getPositionColor(position),
                                size: 24,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: _getPositionColor(position).withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: _getPositionColor(position),
                                size: 24,
                              ),
                            ),
                          )
                        : Container(
                            color: _getPositionColor(position).withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: _getPositionColor(position),
                              size: 24,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Имя
                Text(
                  leader.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                
                // Город
                if (leader.city != null)
                  Text(
                    leader.city!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 4),
                
                // Очки
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPositionColor(position).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${leader.score7d} очков',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getPositionColor(position),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade600; // Золото
      case 2:
        return Colors.grey.shade500; // Серебро
      case 3:
        return Colors.orange.shade600; // Бронза
      default:
        return Theme.of(context).primaryColor;
    }
  }
}

