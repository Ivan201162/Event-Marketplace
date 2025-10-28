import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Экран с политикой конфиденциальности
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Политика конфиденциальности'),
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
              'Политика конфиденциальности',
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
              '1. Сбор информации',
              'Мы собираем информацию, которую вы предоставляете нам напрямую, такую как имя, адрес электронной почты, номер телефона и другую информацию, которую вы решите предоставить.',
            ),
            _buildSection(
              '2. Использование информации',
              'Мы используем собранную информацию для предоставления, поддержки и улучшения наших услуг, а также для связи с вами по поводу вашего аккаунта или наших услуг.',
            ),
            _buildSection(
              '3. Защита информации',
              'Мы принимаем разумные меры для защиты вашей личной информации от несанкционированного доступа, изменения, раскрытия или уничтожения.',
            ),
            _buildSection(
              '4. Обмен информацией',
              'Мы не продаем, не обмениваем и не передаем вашу личную информацию третьим лицам без вашего согласия, за исключением случаев, предусмотренных настоящей политикой.',
            ),
            _buildSection(
              '5. Cookies и аналогичные технологии',
              'Мы используем cookies и аналогичные технологии для улучшения вашего опыта использования нашего приложения.',
            ),
            _buildSection(
              '6. Ваши права',
              'Вы имеете право на доступ, исправление, удаление или ограничение обработки вашей личной информации в соответствии с применимым законодательством.',
            ),
            _buildSection(
              '7. Изменения в политике',
              'Мы можем обновлять эту политику конфиденциальности время от времени. Мы уведомим вас о любых изменениях, разместив новую политику конфиденциальности на этой странице.',
            ),
            _buildSection(
              '8. Контактная информация',
              'Если у вас есть вопросы по поводу этой политики конфиденциальности, пожалуйста, свяжитесь с нами по адресу: privacy@eventmarketplace.com',
            ),
            const SizedBox(height: 32),
            const Text(
              'Соглашаясь с этой политикой конфиденциальности, вы подтверждаете, что понимаете и принимаете условия сбора, использования и защиты вашей личной информации.',
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
