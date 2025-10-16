# 💰 Руководство по интеграции системы монетизации

## 📋 Обзор реализованной системы

Система монетизации Event Marketplace включает:

### 🎯 Основные компоненты:
- **Подписки** (Free, Premium, PRO)
- **Продвижения** (профили, посты, категории)
- **Реклама** (баннеры, спонсорский контент)
- **Платежная система** (Stripe, YooKassa)
- **Система приоритетов** для премиум-пользователей

---

## 🗂️ Структура файлов

### Модели данных:
```
lib/models/
├── subscription_plan.dart      # Планы подписки
├── promotion_boost.dart        # Продвижения
├── advertisement.dart          # Реклама
└── transaction.dart           # Транзакции (расширена)
```

### Сервисы:
```
lib/services/
├── payment_service.dart        # Платежная система
├── subscription_service.dart   # Управление подписками
├── promotion_service.dart      # Управление продвижениями
├── advertisement_service.dart  # Управление рекламой
└── priority_service.dart      # Система приоритетов
```

### UI экраны:
```
lib/screens/monetization/
├── monetization_hub_screen.dart        # Главный экран монетизации
├── subscription_plans_screen.dart      # Планы подписки
├── promotion_packages_screen.dart      # Пакеты продвижения
├── advertisement_campaigns_screen.dart # Рекламные кампании
├── payment_screen.dart                 # Экран оплаты
├── my_subscriptions_screen.dart        # Мои подписки
├── my_promotions_screen.dart           # Мои продвижения
├── my_advertisements_screen.dart       # Моя реклама
└── create_advertisement_screen.dart    # Создание рекламы
```

### Виджеты:
```
lib/widgets/
├── premium_badge_widget.dart   # Премиум-бейджи
└── advertisement_widget.dart   # Виджеты рекламы
```

### Провайдеры:
```
lib/providers/
└── monetization_provider.dart  # Провайдер монетизации
```

---

## 🚀 Интеграция в основное приложение

### 1. Добавление в навигацию

```dart
// В main.dart или app.dart
import 'package:provider/provider.dart';
import 'providers/monetization_provider.dart';
import 'screens/monetization/monetization_hub_screen.dart';

// Добавить провайдер
MultiProvider(
  providers: [
    // ... другие провайдеры
    ChangeNotifierProvider(create: (_) => MonetizationProvider()),
  ],
  child: MyApp(),
)

// В BottomNavigationBar или Drawer
BottomNavigationBarItem(
  icon: Icon(Icons.monetization_on),
  label: 'Монетизация',
)
```

### 2. Интеграция в главный экран

```dart
// В главном экране приложения
class HomeScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Реклама в верхней части
          AdvertisementListWidget(
            placement: AdPlacement.topBanner,
            region: currentRegion,
            city: currentCity,
          ),
          
          // Основной контент
          Expanded(
            child: ListView(
              children: [
                // Продвинутые пользователи
                _buildPromotedUsers(),
                
                // Обычные пользователи
                _buildRegularUsers(),
                
                // Реклама между контентом
                AdvertisementListWidget(
                  placement: AdPlacement.betweenPosts,
                  region: currentRegion,
                  city: currentCity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Интеграция премиум-функций

```dart
// В карточке пользователя
class UserCard extends StatelessWidget {
  final User user;
  final SubscriptionTier userTier;
  
  @override
  Widget build(BuildContext context) {
    return PremiumCardWidget(
      tier: userTier,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
                child: PremiumBadgeWidget(tier: userTier),
              ),
              // ... остальной контент
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 💳 Настройка платежных систем

### 1. Stripe

```dart
// В lib/config/payment_config.dart
class PaymentConfig {
  // Замените на ваши реальные ключи
  static const String stripePublishableKey = 'pk_live_...';
  static const String stripeSecretKey = 'sk_live_...';
}
```

### 2. YooKassa

```dart
// В lib/config/payment_config.dart
class PaymentConfig {
  // Замените на ваши реальные данные
  static const String yookassaShopId = 'your_shop_id';
  static const String yookassaSecretKey = 'your_secret_key';
}
```

---

## 🗄️ Настройка базы данных

### 1. Firestore коллекции

Создайте следующие коллекции в Firestore:

```javascript
// subscription_plans
{
  id: "premium_monthly",
  name: "Премиум (месяц)",
  tier: "premium",
  price: 499.0,
  durationDays: 30,
  features: ["Приоритет в поиске", "Аналитика", "Продвижение"],
  isActive: true
}

// user_subscriptions
{
  id: "sub_123",
  userId: "user_123",
  planId: "premium_monthly",
  startDate: Timestamp,
  endDate: Timestamp,
  status: "active",
  autoRenew: false
}

// promotion_packages
{
  id: "profile_boost_week",
  name: "Продвижение профиля (неделя)",
  type: "profileBoost",
  durationDays: 7,
  price: 299.0,
  priorityLevel: "high",
  isActive: true
}

// promotions
{
  id: "promo_123",
  userId: "user_123",
  type: "profileBoost",
  startDate: Timestamp,
  endDate: Timestamp,
  status: "active",
  priorityLevel: "high",
  price: 299.0
}

// advertisements
{
  id: "ad_123",
  userId: "user_123",
  type: "banner",
  placement: "topBanner",
  startDate: Timestamp,
  endDate: Timestamp,
  status: "active",
  price: 500.0,
  title: "Реклама",
  imageUrl: "https://...",
  targetUrl: "https://..."
}

// transactions
{
  id: "txn_123",
  userId: "user_123",
  type: "subscription",
  amount: 499.0,
  currency: "RUB",
  status: "success",
  timestamp: Timestamp,
  description: "Подписка Премиум",
  subscriptionId: "sub_123",
  paymentMethod: "card",
  paymentProvider: "stripe",
  externalTransactionId: "pi_123"
}
```

### 2. Firestore правила безопасности

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Подписки - только владелец может читать/писать
    match /user_subscriptions/{subscriptionId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Планы подписки - все могут читать
    match /subscription_plans/{planId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.token.admin == true;
    }
    
    // Продвижения - только владелец
    match /promotions/{promotionId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Реклама - владелец может управлять, все могут читать активную
    match /advertisements/{adId} {
      allow read: if resource.data.status == 'active';
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Транзакции - только владелец
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 🧪 Тестирование

### 1. Тестовые данные

```dart
// Создайте тестовые планы подписки
final testPlans = [
  SubscriptionPlan(
    id: 'free',
    name: 'Бесплатный',
    tier: SubscriptionTier.free,
    price: 0.0,
    durationDays: 30,
    features: ['Базовый функционал'],
    isActive: true,
  ),
  SubscriptionPlan(
    id: 'premium_monthly',
    name: 'Премиум (месяц)',
    tier: SubscriptionTier.premium,
    price: 499.0,
    durationDays: 30,
    features: ['Приоритет в поиске', 'Аналитика', 'Продвижение'],
    isActive: true,
  ),
];
```

### 2. Тестирование платежей

```dart
// Используйте тестовые карты Stripe
// 4242 4242 4242 4242 - успешная оплата
// 4000 0000 0000 0002 - отклоненная карта
```

### 3. Проверка функций

```dart
// Тестируйте следующие сценарии:
// 1. Покупка подписки
// 2. Активация премиум-функций
// 3. Продвижение профиля
// 4. Создание рекламы
// 5. Отображение приоритетов
// 6. Уведомления о платежах
```

---

## 📱 Сборка и развертывание

### 1. Очистка и сборка

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 2. Тестирование на устройстве

```bash
flutter install
```

### 3. Проверка функций

- ✅ Покупка подписки
- ✅ Работа premium UI
- ✅ Приоритетная выдача
- ✅ Уведомления
- ✅ Real-time обновление статусов

---

## 🔧 Настройка уведомлений

### 1. Firebase Cloud Messaging

```dart
// Добавьте обработку уведомлений о платежах
class NotificationService {
  static void handlePaymentNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final status = data['status'];
    
    switch (type) {
      case 'subscription':
        if (status == 'success') {
          // Уведомить об успешной активации подписки
        }
        break;
      case 'promotion':
        if (status == 'success') {
          // Уведомить об активации продвижения
        }
        break;
    }
  }
}
```

### 2. In-App уведомления

```dart
// Используйте MonetizationProvider для отслеживания изменений
Consumer<MonetizationProvider>(
  builder: (context, provider, child) {
    if (provider.hasActiveSubscription) {
      // Показать премиум-функции
    }
    return child!;
  },
)
```

---

## 📊 Мониторинг и аналитика

### 1. Отслеживание метрик

```dart
// Добавьте аналитику для ключевых событий
AnalyticsService.trackEvent('subscription_purchased', {
  'plan_id': planId,
  'price': price,
  'currency': 'RUB',
});

AnalyticsService.trackEvent('promotion_activated', {
  'type': promotionType,
  'duration': durationDays,
});
```

### 2. Дашборд администратора

```dart
// Создайте экран для просмотра статистики
class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationProvider>(
      builder: (context, provider, child) {
        final stats = provider.stats;
        return Column(
          children: [
            Text('Общая выручка: ${stats['totalRevenue']} ₽'),
            Text('Активных подписок: ${stats['subscriptions']['activeSubscriptions']}'),
            Text('Активных продвижений: ${stats['promotions']['activePromotions']}'),
          ],
        );
      },
    );
  }
}
```

---

## 🎯 Следующие шаги

1. **Настройте реальные платежные ключи**
2. **Создайте тестовые данные в Firestore**
3. **Протестируйте все функции монетизации**
4. **Настройте уведомления**
5. **Добавьте аналитику**
6. **Создайте админ-панель**

---

## 📞 Поддержка

При возникновении проблем:

1. Проверьте логи в консоли
2. Убедитесь в правильности конфигурации
3. Проверьте права доступа в Firestore
4. Протестируйте на реальном устройстве

**Система монетизации готова к использованию! 🚀**
