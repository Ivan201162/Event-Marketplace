import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран с пользовательским соглашением
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользовательское соглашение'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пользовательское соглашение',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Последнее обновление: ${_lastUpdated}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Принятие условий',
              'Используя наше приложение, вы соглашаетесь с условиями данного пользовательского соглашения. Если вы не согласны с какими-либо условиями, пожалуйста, не используйте наше приложение.',
            ),
            _buildSection(
              '2. Описание сервиса',
              'Event Marketplace - это платформа для поиска и бронирования специалистов для проведения мероприятий. Мы предоставляем инструменты для связи между заказчиками и специалистами.',
            ),
            _buildSection(
              '3. Регистрация и аккаунт',
              'Для использования наших услуг вам необходимо создать аккаунт. Вы несете ответственность за сохранность ваших учетных данных и за все действия, совершенные под вашим аккаунтом.',
            ),
            _buildSection(
              '4. Правила использования',
              'Вы обязуетесь использовать наше приложение только в законных целях и в соответствии с настоящим соглашением. Запрещается размещение незаконного, вредоносного или оскорбительного контента.',
            ),
            _buildSection(
              '5. Интеллектуальная собственность',
              'Все права на интеллектуальную собственность в отношении нашего приложения и его содержимого принадлежат нам или нашим лицензиарам.',
            ),
            _buildSection(
              '6. Платежи и возмещения',
              'Платежи обрабатываются через безопасные платежные системы. Политика возмещений определяется индивидуально для каждого случая.',
            ),
            _buildSection(
              '7. Ответственность',
              'Мы не несем ответственности за качество услуг, предоставляемых специалистами через нашу платформу. Мы выступаем только в качестве посредника.',
            ),
            _buildSection(
              '8. Прекращение действия',
              'Мы оставляем за собой право прекратить или приостановить ваш доступ к приложению в любое время без предварительного уведомления.',
            ),
            _buildSection(
              '9. Изменения в соглашении',
              'Мы можем изменять данное соглашение в любое время. Изменения вступают в силу с момента их публикации в приложении.',
            ),
            _buildSection(
              '10. Контактная информация',
              'По вопросам, связанным с данным соглашением, обращайтесь по адресу: support@eventmarketplace.com',
            ),
            const SizedBox(height: 32),
            const Text(
              'Используя наше приложение, вы подтверждаете, что прочитали, поняли и согласились с условиями данного пользовательского соглашения.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

const String _lastUpdated = '1 января 2024 года';
