import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';

/// Провайдер сервиса поддержки
final supportServiceProvider = Provider<SupportService>((ref) => SupportService());

/// Провайдер для получения тикетов пользователя
final userTicketsProvider = StreamProvider.family<List<SupportTicket>, String>(
  (ref, userId) => ref.watch(supportServiceProvider).getUserTickets(userId),
);

/// Провайдер для получения всех тикетов (для админов)
final allTicketsProvider = StreamProvider<List<SupportTicket>>(
  (ref) => ref.watch(supportServiceProvider).getAllTickets(),
);

/// Провайдер для получения тикета по ID
final ticketProvider = FutureProvider.family<SupportTicket?, String>(
  (ref, ticketId) => ref.watch(supportServiceProvider).getTicket(ticketId),
);

/// Провайдер для получения сообщений тикета
final ticketMessagesProvider = StreamProvider.family<List<SupportMessage>, String>(
  (ref, ticketId) => ref.watch(supportServiceProvider).getTicketMessages(ticketId),
);

/// Провайдер для получения FAQ
final faqProvider = StreamProvider.family<List<FAQItem>, SupportCategory?>(
  (ref, category) => ref.watch(supportServiceProvider).getFAQ(category),
);

/// Провайдер для получения статистики поддержки
final supportStatsProvider = FutureProvider<SupportStats>(
  (ref) => ref.watch(supportServiceProvider).getSupportStats('current_user'),
);
