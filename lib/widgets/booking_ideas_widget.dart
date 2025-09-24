import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/idea.dart';
import '../models/event_idea.dart';
import '../models/booking.dart';
import '../services/booking_ideas_service.dart';
import '../core/constants/app_routes.dart';

/// Виджет для отображения идей в заявке
class BookingIdeasWidget extends StatefulWidget {
  const BookingIdeasWidget({
    super.key,
    required this.booking,
    this.isSpecialistView = false,
    this.onIdeasChanged,
  });

  final Booking booking;
  final bool isSpecialistView;
  final VoidCallback? onIdeasChanged;

  @override
  State<BookingIdeasWidget> createState() => _BookingIdeasWidgetState();
}

class _BookingIdeasWidgetState extends State<BookingIdeasWidget> {
  final BookingIdeasService _bookingIdeasService = BookingIdeasService();
  List<Idea> _ideas = [];
  List<EventIdea> _eventIdeas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _bookingIdeasService.getBookingIdeas(widget.booking.id),
        _bookingIdeasService.getBookingEventIdeas(widget.booking.id),
      ]);

      setState(() {
        _ideas = futures[0] as List<Idea>;
        _eventIdeas = futures[1] as List<EventIdea>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки идей: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalIdeas = _ideas.length + _eventIdeas.length;

    if (totalIdeas == 0) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildIdeasGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    final totalIdeas = _ideas.length + _eventIdeas.length;
    
    return Row(
      children: [
        Icon(
          Icons.lightbulb,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Идеи и вдохновение ($totalIdeas)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (!widget.isSpecialistView)
          TextButton.icon(
            onPressed: _showAddIdeasDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Добавить'),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.isSpecialistView 
                ? 'Клиент пока не добавил идеи'
                : 'Добавьте идеи для вдохновения',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isSpecialistView
                ? 'Когда клиент прикрепит идеи, они появятся здесь'
                : 'Поделитесь идеями с исполнителем для лучшего понимания вашего видения',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (!widget.isSpecialistView) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddIdeasDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить идеи'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdeasGrid() {
    final allIdeas = <Widget>[];

    // Добавляем обычные идеи
    for (final idea in _ideas) {
      allIdeas.add(_buildIdeaCard(idea));
    }

    // Добавляем идеи мероприятий
    for (final eventIdea in _eventIdeas) {
      allIdeas.add(_buildEventIdeaCard(eventIdea));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allIdeas.length,
      itemBuilder: (context, index) => allIdeas[index],
    );
  }

  Widget _buildIdeaCard(Idea idea) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showIdeaDetails(idea),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (idea.images.isNotEmpty)
              Expanded(
                flex: 3,
                child: Image.network(
                  idea.images.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.red[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${idea.likesCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        if (!widget.isSpecialistView)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeIdea(idea),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventIdeaCard(EventIdea eventIdea) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEventIdeaDetails(eventIdea),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eventIdea.imageUrl.isNotEmpty)
              Expanded(
                flex: 3,
                child: Image.network(
                  eventIdea.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 32, color: Colors.grey),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventIdea.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eventIdea.categoryDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 14,
                          color: Colors.red[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${eventIdea.likesCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        if (!widget.isSpecialistView)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeEventIdea(eventIdea),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIdeasDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить идеи'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Идеи мероприятий'),
              subtitle: const Text('Просмотреть и добавить идеи'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.ideas);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Сохраненные идеи'),
              subtitle: const Text('Добавить из избранного'),
              onTap: () {
                Navigator.of(context).pop();
                _showSavedIdeasDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showSavedIdeasDialog() {
    // TODO: Реализовать диалог с сохраненными идеями
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция добавления из избранного будет добавлена')),
    );
  }

  void _showIdeaDetails(Idea idea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (idea.images.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(idea.images.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                idea.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                idea.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: idea.authorAvatar != null
                        ? NetworkImage(idea.authorAvatar!)
                        : null,
                    child: idea.authorAvatar == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${idea.createdAt.day}.${idea.createdAt.month}.${idea.createdAt.year}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red[300],
                  ),
                  const SizedBox(width: 4),
                  Text('${idea.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.bookmark,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(width: 4),
                  Text('${idea.savesCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventIdeaDetails(EventIdea eventIdea) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eventIdea.imageUrl.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(eventIdea.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                eventIdea.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                eventIdea.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Тип: ${eventIdea.typeDisplayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Категория: ${eventIdea.categoryDisplayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.red[300],
                  ),
                  const SizedBox(width: 4),
                  Text('${eventIdea.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.bookmark,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(width: 4),
                  Text('${eventIdea.savesCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeIdea(Idea idea) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить идею'),
        content: const Text('Вы уверены, что хотите удалить эту идею из заявки?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingIdeasService.detachIdeaFromBooking(
          bookingId: widget.booking.id,
          ideaId: idea.id,
        );
        await _loadIdeas();
        widget.onIdeasChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Идея удалена из заявки'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления идеи: $e');
      }
    }
  }

  Future<void> _removeEventIdea(EventIdea eventIdea) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить идею'),
        content: const Text('Вы уверены, что хотите удалить эту идею из заявки?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bookingIdeasService.detachEventIdeaFromBooking(
          bookingId: widget.booking.id,
          eventIdeaId: eventIdea.id,
        );
        await _loadIdeas();
        widget.onIdeasChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Идея удалена из заявки'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления идеи: $e');
      }
    }
  }
}
