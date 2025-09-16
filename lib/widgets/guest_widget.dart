import 'package:flutter/material.dart';
import '../models/guest.dart';

/// Виджет гостя
class GuestWidget extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final VoidCallback? onCancel;
  final VoidCallback? onShare;

  const GuestWidget({
    super.key,
    required this.guest,
    this.onTap,
    this.onCheckIn,
    this.onCheckOut,
    this.onCancel,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Аватар гостя
              CircleAvatar(
                radius: 24,
                backgroundImage: guest.guestPhotoUrl != null
                    ? NetworkImage(guest.guestPhotoUrl!)
                    : null,
                child: guest.guestPhotoUrl == null
                    ? Text(
                        guest.guestName.isNotEmpty
                            ? guest.guestName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 18),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя гостя
                    Text(
                      guest.guestName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      guest.guestEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    // Телефон
                    if (guest.guestPhone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        guest.guestPhone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Статус и дополнительная информация
                    Row(
                      children: [
                        // Статус
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: guest.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: guest.statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            guest.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: guest.statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Поздравления
                        if (guest.greetingsCount > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.celebration,
                                size: 16,
                                color: Colors.pink[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                guest.greetingsCount.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.pink[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Действия
              if (onCheckIn != null ||
                  onCheckOut != null ||
                  onCancel != null ||
                  onShare != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'checkin':
                        onCheckIn?.call();
                        break;
                      case 'checkout':
                        onCheckOut?.call();
                        break;
                      case 'cancel':
                        onCancel?.call();
                        break;
                      case 'share':
                        onShare?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onCheckIn != null &&
                        guest.status == GuestStatus.registered)
                      const PopupMenuItem(
                        value: 'checkin',
                        child: Row(
                          children: [
                            Icon(Icons.login, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Регистрация'),
                          ],
                        ),
                      ),
                    if (onCheckOut != null &&
                        guest.status == GuestStatus.checkedIn)
                      const PopupMenuItem(
                        value: 'checkout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Выход'),
                          ],
                        ),
                      ),
                    if (onCancel != null &&
                        guest.status != GuestStatus.cancelled)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Отменить'),
                          ],
                        ),
                      ),
                    if (onShare != null)
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Поделиться'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для отображения гостя в списке
class GuestListTile extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final VoidCallback? onCancel;
  final VoidCallback? onShare;

  const GuestListTile({
    super.key,
    required this.guest,
    this.onTap,
    this.onCheckIn,
    this.onCheckOut,
    this.onCancel,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: guest.guestPhotoUrl != null
            ? NetworkImage(guest.guestPhotoUrl!)
            : null,
        child: guest.guestPhotoUrl == null
            ? Text(
                guest.guestName.isNotEmpty
                    ? guest.guestName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 16),
              )
            : null,
      ),
      title: Text(
        guest.guestName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guest.guestEmail),
          if (guest.guestPhone != null) Text(guest.guestPhone!),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: guest.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: guest.statusColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  guest.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: guest.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (guest.greetingsCount > 0) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 14,
                      color: Colors.pink[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      guest.greetingsCount.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCheckIn != null && guest.status == GuestStatus.registered)
            IconButton(
              icon: const Icon(Icons.login, color: Colors.green),
              onPressed: onCheckIn,
              tooltip: 'Регистрация',
            ),
          if (onCheckOut != null && guest.status == GuestStatus.checkedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.orange),
              onPressed: onCheckOut,
              tooltip: 'Выход',
            ),
          if (onCancel != null && guest.status != GuestStatus.cancelled)
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: onCancel,
              tooltip: 'Отменить',
            ),
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onShare,
              tooltip: 'Поделиться',
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Виджет для отображения гостя в сетке
class GuestGridTile extends StatelessWidget {
  final Guest guest;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final VoidCallback? onCancel;
  final VoidCallback? onShare;

  const GuestGridTile({
    super.key,
    required this.guest,
    this.onTap,
    this.onCheckIn,
    this.onCheckOut,
    this.onCancel,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Аватар
              CircleAvatar(
                radius: 30,
                backgroundImage: guest.guestPhotoUrl != null
                    ? NetworkImage(guest.guestPhotoUrl!)
                    : null,
                child: guest.guestPhotoUrl == null
                    ? Text(
                        guest.guestName.isNotEmpty
                            ? guest.guestName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),

              const SizedBox(height: 8),

              // Имя
              Text(
                guest.guestName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Статус
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: guest.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: guest.statusColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  guest.statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: guest.statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Поздравления
              if (guest.greetingsCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.celebration,
                      size: 12,
                      color: Colors.pink[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      guest.greetingsCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.pink[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет для отображения статистики гостя
class GuestStatsWidget extends StatelessWidget {
  final Guest guest;

  const GuestStatsWidget({
    super.key,
    required this.guest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о госте',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Основная информация
            _buildInfoRow('Имя', guest.guestName),
            _buildInfoRow('Email', guest.guestEmail),
            if (guest.guestPhone != null)
              _buildInfoRow('Телефон', guest.guestPhone!),
            _buildInfoRow('Статус', guest.statusText),

            const SizedBox(height: 16),

            // Временные метки
            if (guest.registeredAt != null)
              _buildInfoRow(
                  'Зарегистрирован', _formatDateTime(guest.registeredAt!)),
            if (guest.confirmedAt != null)
              _buildInfoRow('Подтвержден', _formatDateTime(guest.confirmedAt!)),
            if (guest.checkedInAt != null)
              _buildInfoRow(
                  'На мероприятии', _formatDateTime(guest.checkedInAt!)),
            if (guest.checkedOutAt != null)
              _buildInfoRow('Покинул', _formatDateTime(guest.checkedOutAt!)),

            const SizedBox(height: 16),

            // Поздравления
            if (guest.greetingsCount > 0)
              _buildInfoRow('Поздравлений', guest.greetingsCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
