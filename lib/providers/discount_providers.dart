import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mock discount service provider
final discountServiceProvider = Provider<DiscountService>((ref) {
  return DiscountService();
});

/// Mock discount service
class DiscountService {
  Future<void> applyDiscount(String discountCode) async {
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> removeDiscount() async {
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<bool> validateDiscount(String discountCode) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return discountCode.isNotEmpty;
  }

  Future<void> acceptDiscount(String discountId,
      {String? bookingId, String? customerId}) async {
    // Mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }
}
