import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_ticket.dart';
import '../services/support_service.dart';
import '../widgets/support_ticket_widget.dart';
import 'admin_support_screen.dart';
import 'create_support_ticket_screen.dart';
import 'faq_screen.dart';
import 'support_ticket_detail_screen.dart';

/// Главный экран поддержки
class SupportMainScreen extends ConsumerStatefulWidget {
  const SupportMainScreen({super.key});

  @override
  ConsumerState<SupportMainScreen> createState() => _SupportMainScreenState();
}

class _SupportMainScreenState extends ConsumerState<SupportMainScreen> {
  final SupportService _supportService = SupportService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поддержка'),
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _showAdminPanel,
            ),
          ],
        ),
        body: Column(
          children: [
            // Быстрые действия
            _buildQuickActions(),

            // FAQ секция
            _buildFAQSection(),

            // Мои тикеты
            Expanded(
              child: _buildMyTicketsSection(),
            ),
          ],
        ),
      );

  Widget _buildQuickActions() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.add,
                title: 'Создать тикет',
                subtitle: 'Получить помощь',
                color: Colors.blue,
                onTap: _createTicket,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.help_outline,
                title: 'FAQ',
                subtitle: 'Частые вопросы',
                color: Colors.green,
                onTap: _showFAQ,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.phone,
                title: 'Связаться',
                subtitle: 'Прямой контакт',
                color: Colors.orange,
                onTap: _contactSupport,
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFAQSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Часто задаваемые вопросы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showFAQ,
                  child: const Text('Все'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: StreamBuilder<List<FAQItem>>(
                stream: _supportService.getFAQ(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final faqItems = snapshot.data ?? [];
                  if (faqItems.isEmpty) {
                    return const Center(
                      child: Text('Нет FAQ'),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: faqItems.length,
                    itemBuilder: (context, index) {
                      final faqItem = faqItems[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          child: InkWell(
                            onTap: () => _showFAQDetail(faqItem),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        faqItem.category.icon,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        faqItem.category.categoryText,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.visibility,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${faqItem.viewsCount}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    faqItem.question,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    faqItem.answer,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildMyTicketsSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Мои тикеты поддержки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<SupportTicket>>(
                stream: _supportService.getUserTickets(
                  'demo_user_id',
                ), // TODO(developer): Получить из контекста
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Ошибка: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }

                  final tickets = snapshot.data ?? [];
                  if (tickets.isEmpty) {
                    return _buildEmptyTicketsState();
                  }

                  return ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return SupportTicketWidget(
                        ticket: ticket,
                        onTap: () => _showTicketDetail(ticket),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyTicketsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет тикетов поддержки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте тикет для получения помощи',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createTicket,
              icon: const Icon(Icons.add),
              label: const Text('Создать тикет'),
            ),
          ],
        ),
      );

  void _createTicket() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<bool>(
        builder: (context) => const CreateSupportTicketScreen(),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showTicketDetail(SupportTicket ticket) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<bool>(
        builder: (context) => SupportTicketDetailScreen(
          ticketId: ticket.id,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showFAQ() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FAQScreen(),
      ),
    );
  }

  void _showFAQDetail(FAQItem faqItem) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(faqItem.question),
        content: SingleChildScrollView(
          child: Text(
            faqItem.answer,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTicketFromFAQ(faqItem);
            },
            child: const Text('Создать тикет'),
          ),
        ],
      ),
    );

    // Увеличиваем счетчик просмотров
    _supportService.incrementFAQViews(faqItem.id);
  }

  void _createTicketFromFAQ(FAQItem faqItem) {
    // TODO(developer): Перейти к созданию тикета с предзаполненной информацией
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Создание тикета для: ${faqItem.question}')),
    );
  }

  void _contactSupport() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Связаться с поддержкой'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@eventmarketplace.com'),
            SizedBox(height: 8),
            Text('Телефон: +7 (800) 123-45-67'),
            SizedBox(height: 8),
            Text('Время работы: 9:00 - 18:00 (МСК)'),
            SizedBox(height: 8),
            Text('Telegram: @eventmarketplace_support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTicket();
            },
            child: const Text('Создать тикет'),
          ),
        ],
      ),
    );
  }

  void _showAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AdminSupportScreen(),
      ),
    );
  }
}
