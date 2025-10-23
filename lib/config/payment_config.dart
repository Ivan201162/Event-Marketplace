class PaymentConfig {
  // ========================================
  // 🔑 НАСТРОЙКИ ПЛАТЕЖНЫХ СИСТЕМ
  // ========================================

  // Stripe Configuration
  // Получите ключи на https://dashboard.stripe.com/apikeys
  static const String stripePublishableKey =
      'pk_test_51O8X...'; // Замените на ваш publishable key
  static const String stripeSecretKey =
      'sk_test_51O8X...'; // Замените на ваш secret key

  // YooKassa Configuration
  // Получите ключи на https://yookassa.ru/my
  static const String yookassaShopId =
      'your_shop_id'; // Замените на ваш Shop ID
  static const String yookassaSecretKey =
      'test_your_secret_key'; // Замените на ваш secret key

  // CloudPayments Configuration
  static const String cloudPaymentsPublicId = 'your_public_id';
  static const String cloudPaymentsApiSecret = 'your_api_secret';

  // Tinkoff Pay Configuration
  static const String tinkoffTerminalKey = 'your_terminal_key';
  static const String tinkoffPassword = 'your_password';

  // ========================================
  // 💰 НАСТРОЙКИ ПЛАТЕЖЕЙ
  // ========================================

  static const String defaultCurrency = 'RUB';
  static const double minPaymentAmount = 1.0;
  static const double maxPaymentAmount = 100000.0;

  // ========================================
  // 📋 ПЛАНЫ ПОДПИСКИ
  // ========================================

  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'free': {
      'name': 'Бесплатный',
      'price': 0.0,
      'durationDays': 30,
      'features': [
        'Базовый поиск специалистов',
        'Просмотр профилей',
        'Ограниченные фильтры',
        'До 5 сообщений в день',
      ],
    },
    'premium_monthly': {
      'name': 'Премиум (месяц)',
      'price': 499.0,
      'durationDays': 30,
      'features': [
        'Приоритет в поиске',
        'Расширенная аналитика',
        'Неограниченные сообщения',
        'Продвижение профиля',
        'Доступ к премиум-фильтрам',
        'Приоритетная поддержка',
      ],
    },
    'premium_yearly': {
      'name': 'Премиум (год)',
      'price': 3999.0,
      'durationDays': 365,
      'features': [
        'Приоритет в поиске',
        'Расширенная аналитика',
        'Неограниченные сообщения',
        'Продвижение профиля',
        'Доступ к премиум-фильтрам',
        'Приоритетная поддержка',
        'Скидка 33%',
      ],
    },
    'pro_monthly': {
      'name': 'PRO (месяц)',
      'price': 999.0,
      'durationDays': 30,
      'features': [
        'Все функции Премиум',
        'Максимальный приоритет',
        'Персональный менеджер',
        'API доступ',
        'Кастомные интеграции',
        'Белый лейбл',
        'Расширенная аналитика',
      ],
    },
    'pro_yearly': {
      'name': 'PRO (год)',
      'price': 7999.0,
      'durationDays': 365,
      'features': [
        'Все функции Премиум',
        'Максимальный приоритет',
        'Персональный менеджер',
        'API доступ',
        'Кастомные интеграции',
        'Белый лейбл',
        'Расширенная аналитика',
        'Скидка 33%',
      ],
    },
  };

  // ========================================
  // 🚀 ПАКЕТЫ ПРОДВИЖЕНИЯ
  // ========================================

  static const Map<String, Map<String, dynamic>> promotionPackages = {
    'profile_boost_3days': {
      'name': 'Продвижение профиля (3 дня)',
      'type': 'profileBoost',
      'price': 199.0,
      'durationDays': 3,
      'priorityLevel': 'medium',
      'features': [
        'Выделение в списке',
        'Приоритет в поиске',
        'Золотая рамка профиля'
      ],
    },
    'profile_boost_week': {
      'name': 'Продвижение профиля (неделя)',
      'type': 'profileBoost',
      'price': 399.0,
      'durationDays': 7,
      'priorityLevel': 'high',
      'features': [
        'Выделение в списке',
        'Приоритет в поиске',
        'Золотая рамка профиля',
        'Топ позиция',
      ],
    },
    'profile_boost_month': {
      'name': 'Продвижение профиля (месяц)',
      'type': 'profileBoost',
      'price': 1299.0,
      'durationDays': 30,
      'priorityLevel': 'premium',
      'features': [
        'Выделение в списке',
        'Приоритет в поиске',
        'Золотая рамка профиля',
        'Топ позиция',
        'Премиум-бейдж',
      ],
    },
    'post_boost_3days': {
      'name': 'Продвижение поста (3 дня)',
      'type': 'postBoost',
      'price': 99.0,
      'durationDays': 3,
      'priorityLevel': 'medium',
      'features': [
        'Увеличение охвата',
        'Приоритет в ленте',
        'Аналитика просмотров'
      ],
    },
    'post_boost_week': {
      'name': 'Продвижение поста (неделя)',
      'type': 'postBoost',
      'price': 199.0,
      'durationDays': 7,
      'priorityLevel': 'high',
      'features': [
        'Увеличение охвата',
        'Приоритет в ленте',
        'Аналитика просмотров',
        'Таргетинг аудитории',
      ],
    },
  };

  // ========================================
  // 📢 РЕКЛАМНЫЕ ТАРИФЫ
  // ========================================

  static const Map<String, Map<String, dynamic>> advertisementRates = {
    'banner_top': {
      'name': 'Верхний баннер',
      'type': 'banner',
      'placement': 'topBanner',
      'pricePerDay': 500.0,
      'minDuration': 1,
      'maxDuration': 30,
      'features': [
        'Высокая видимость',
        'Таргетинг по региону',
        'Аналитика показов'
      ],
    },
    'banner_bottom': {
      'name': 'Нижний баннер',
      'type': 'banner',
      'placement': 'bottomBanner',
      'pricePerDay': 300.0,
      'minDuration': 1,
      'maxDuration': 30,
      'features': [
        'Хорошая видимость',
        'Таргетинг по региону',
        'Аналитика показов'
      ],
    },
    'sponsored_post': {
      'name': 'Спонсорский пост',
      'type': 'sponsoredPost',
      'placement': 'homeFeed',
      'pricePerDay': 1000.0,
      'minDuration': 1,
      'maxDuration': 7,
      'features': [
        'Органичный вид',
        'Высокий CTR',
        'Детальная аналитика',
        'Таргетинг аудитории'
      ],
    },
    'category_ad': {
      'name': 'Реклама в категории',
      'type': 'categoryAd',
      'placement': 'categoryList',
      'pricePerDay': 200.0,
      'minDuration': 1,
      'maxDuration': 30,
      'features': [
        'Таргетинг по категории',
        'Аналитика кликов',
        'Региональный таргетинг'
      ],
    },
  };

  // ========================================
  // 🎁 ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ
  // ========================================

  // Суммы для быстрых донатов
  static const List<double> quickDonationAmounts = [
    100.0,
    300.0,
    500.0,
    1000.0,
    2000.0,
    5000.0
  ];

  // Минимальные суммы для разных типов платежей
  static const Map<String, double> minAmounts = {
    'subscription': 1.0,
    'promotion': 50.0,
    'advertisement': 100.0,
    'donation': 10.0,
  };

  // Максимальные суммы для разных типов платежей
  static const Map<String, double> maxAmounts = {
    'subscription': 50000.0,
    'promotion': 10000.0,
    'advertisement': 100000.0,
    'donation': 100000.0,
  };

  // ========================================
  // 🔧 НАСТРОЙКИ РАЗРАБОТКИ
  // ========================================

  static const bool isDevelopment = true;
  static const bool enableTestPayments = true;
  static const bool enableLogging = true;

  // URL для редиректов после оплаты
  static const String successUrl =
      'https://eventmarketplace.app/payment/success';
  static const String cancelUrl = 'https://eventmarketplace.app/payment/cancel';

  // ========================================
  // 📊 НАСТРОЙКИ АНАЛИТИКИ
  // ========================================

  static const Map<String, String> analyticsEvents = {
    'subscription_purchased': 'subscription_purchased',
    'promotion_activated': 'promotion_activated',
    'advertisement_created': 'advertisement_created',
    'payment_success': 'payment_success',
    'payment_failed': 'payment_failed',
  };

  // ========================================
  // 🔔 НАСТРОЙКИ УВЕДОМЛЕНИЙ
  // ========================================

  static const Map<String, String> notificationTemplates = {
    'subscription_activated': 'Ваша подписка активирована!',
    'subscription_expiring': 'Подписка истекает через 3 дня',
    'promotion_activated': 'Продвижение активировано!',
    'payment_success': 'Платеж успешно обработан',
    'payment_failed': 'Ошибка обработки платежа',
  };
}
