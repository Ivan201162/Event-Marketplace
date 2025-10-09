class PaymentConfig {
  // Stripe Configuration (Test Keys)
  static const String stripePublishableKey = 'pk_test_51234567890abcdefghijklmnopqrstuvwxyz';
  static const String stripeSecretKey = 'sk_test_51234567890abcdefghijklmnopqrstuvwxyz';
  
  // YooKassa Configuration (Test Keys)
  static const String yookassaShopId = '123456';
  static const String yookassaSecretKey = 'test_1234567890abcdefghijklmnopqrstuvwxyz';
  
  // Payment Settings
  static const String defaultCurrency = 'RUB';
  static const double minDonationAmount = 100.0;
  static const double maxDonationAmount = 10000.0;
  
  // Premium Plans
  static const Map<String, double> premiumPlans = {
    '7_days': 299.0,
    '14_days': 499.0,
    '30_days': 899.0,
  };
  
  // Subscription Plans
  static const Map<String, double> subscriptionPlans = {
    'standard': 0.0,
    'pro': 499.0,
    'elite': 999.0,
  };
  
  // Donation Amounts
  static const List<double> donationAmounts = [100.0, 300.0, 500.0, 1000.0];
}


