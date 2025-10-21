import 'package:flutter/foundation.dart';

import '../models/advertisement.dart';
import '../models/promotion_boost.dart';
import '../models/subscription_plan.dart';
import '../services/advertisement_service.dart';
import '../services/priority_service.dart';
import '../services/promotion_service.dart';
import '../services/subscription_service.dart';

class MonetizationProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final PromotionService _promotionService = PromotionService();
  final AdvertisementService _advertisementService = AdvertisementService();
  final PriorityService _priorityService = PriorityService();

  // Состояние
  bool _isLoading = false;
  String? _error;

  // Данные
  List<SubscriptionPlan> _subscriptionPlans = [];
  List<PromotionPackage> _promotionPackages = [];
  List<AdCampaign> _adCampaigns = [];
  final List<Advertisement> _advertisements = [];

  UserSubscription? _activeSubscription;
  List<PromotionBoost> _activePromotions = [];
  List<Advertisement> _activeAdvertisements = [];

  Map<String, dynamic> _stats = {};
  int _userPriority = 0;
  SubscriptionTier _userTier = SubscriptionTier.free;

  // Геттеры
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;
  List<PromotionPackage> get promotionPackages => _promotionPackages;
  List<AdCampaign> get adCampaigns => _adCampaigns;
  List<Advertisement> get advertisements => _advertisements;

  UserSubscription? get activeSubscription => _activeSubscription;
  List<PromotionBoost> get activePromotions => _activePromotions;
  List<Advertisement> get activeAdvertisements => _activeAdvertisements;

  Map<String, dynamic> get stats => _stats;
  int get userPriority => _userPriority;
  SubscriptionTier get userTier => _userTier;

  bool get hasActiveSubscription => _activeSubscription != null && _activeSubscription!.isActive;
  bool get hasActivePromotions => _activePromotions.isNotEmpty;
  bool get hasActiveAdvertisements => _activeAdvertisements.isNotEmpty;
  bool get isPremiumUser => _userTier != SubscriptionTier.free;

  /// Загрузка всех данных монетизации
  Future<void> loadMonetizationData(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _loadSubscriptionPlans(),
        _loadPromotionPackages(),
        _loadUserSubscriptions(userId),
        _loadUserPromotions(userId),
        _loadUserAdvertisements(userId),
        _loadUserPriority(userId),
        _loadStats(),
      ]);
    } catch (e) {
      _setError('Ошибка загрузки данных монетизации: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Загрузка планов подписки
  Future<void> _loadSubscriptionPlans() async {
    try {
      _subscriptionPlans = await _subscriptionService.getAvailablePlans();
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки планов подписки: $e');
    }
  }

  /// Загрузка пакетов продвижения
  Future<void> _loadPromotionPackages() async {
    try {
      _promotionPackages = await _promotionService.getAvailablePackages();
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки пакетов продвижения: $e');
    }
  }

  /// Загрузка подписок пользователя
  Future<void> _loadUserSubscriptions(String userId) async {
    try {
      _activeSubscription = await _subscriptionService.getActiveSubscription(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки подписок: $e');
    }
  }

  /// Загрузка продвижений пользователя
  Future<void> _loadUserPromotions(String userId) async {
    try {
      _activePromotions = await _promotionService.getActivePromotions(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки продвижений: $e');
    }
  }

  /// Загрузка рекламы пользователя
  Future<void> _loadUserAdvertisements(String userId) async {
    try {
      _adCampaigns = await _advertisementService.getUserCampaigns(userId);
      _activeAdvertisements = [];
      for (final campaign in _adCampaigns) {
        _activeAdvertisements.addAll(campaign.ads.where((ad) => ad.isActive));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки рекламы: $e');
    }
  }

  /// Загрузка приоритета пользователя
  Future<void> _loadUserPriority(String userId) async {
    try {
      _userPriority = await _priorityService.getUserPriority(userId);
      _userTier = await _priorityService.getUserSubscriptionTier(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки приоритета: $e');
    }
  }

  /// Загрузка статистики
  Future<void> _loadStats() async {
    try {
      _stats = await _priorityService.getPriorityStats();
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка загрузки статистики: $e');
    }
  }

  /// Покупка подписки
  Future<bool> purchaseSubscription({required String userId, required String planId}) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Интеграция с экраном оплаты
      // Здесь должна быть логика покупки подписки

      // После успешной покупки обновляем данные
      await _loadUserSubscriptions(userId);
      await _loadUserPriority(userId);

      return true;
    } catch (e) {
      _setError('Ошибка покупки подписки: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Покупка продвижения
  Future<bool> purchasePromotion({required String userId, required String packageId}) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Интеграция с экраном оплаты
      // Здесь должна быть логика покупки продвижения

      // После успешной покупки обновляем данные
      await _loadUserPromotions(userId);
      await _loadUserPriority(userId);

      return true;
    } catch (e) {
      _setError('Ошибка покупки продвижения: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Создание рекламы
  Future<bool> createAdvertisement({
    required String userId,
    required Advertisement advertisement,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Интеграция с экраном создания рекламы
      // Здесь должна быть логика создания рекламы

      // После успешного создания обновляем данные
      await _loadUserAdvertisements(userId);

      return true;
    } catch (e) {
      _setError('Ошибка создания рекламы: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Отмена подписки
  Future<bool> cancelSubscription(String subscriptionId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _subscriptionService.cancelSubscription(subscriptionId);
      if (success) {
        // Обновляем данные после отмены
        if (_activeSubscription?.id == subscriptionId) {
          _activeSubscription = null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Ошибка отмены подписки: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Отмена продвижения
  Future<bool> cancelPromotion(String promotionId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _promotionService.cancelPromotion(promotionId);
      if (success) {
        // Обновляем данные после отмены
        _activePromotions.removeWhere((p) => p.id == promotionId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Ошибка отмены продвижения: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Пауза продвижения
  Future<bool> pausePromotion(String promotionId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _promotionService.pausePromotion(promotionId);
      if (success) {
        // Обновляем данные после паузы
        final index = _activePromotions.indexWhere((p) => p.id == promotionId);
        if (index != -1) {
          _activePromotions.removeAt(index);
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Ошибка паузы продвижения: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Возобновление продвижения
  Future<bool> resumePromotion(String promotionId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _promotionService.resumePromotion(promotionId);
      if (success) {
        // Обновляем данные после возобновления
        // TODO: Перезагрузить продвижения пользователя
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Ошибка возобновления продвижения: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Пауза рекламы
  Future<bool> pauseAdvertisement(String adId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _advertisementService.pauseAdvertisement(adId);
      if (success) {
        // Обновляем данные после паузы
        _activeAdvertisements.removeWhere((ad) => ad.id == adId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Ошибка паузы рекламы: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Возобновление рекламы
  Future<bool> resumeAdvertisement(String adId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _advertisementService.resumeAdvertisement(adId);
      if (success) {
        // Обновляем данные после возобновления
        // TODO: Перезагрузить рекламу пользователя
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Ошибка возобновления рекламы: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Обновление статистики
  Future<void> updateDisplayStats({
    required String userId,
    required String type,
    required String itemId,
    bool isClick = false,
  }) async {
    try {
      await _priorityService.updateDisplayStats(
        userId: userId,
        type: type,
        itemId: itemId,
        isClick: isClick,
      );
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка обновления статистики: $e');
    }
  }

  /// Получение рекомендаций
  Future<List<Map<String, dynamic>>> getRecommendations({
    required String userId,
    String? region,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      return await _priorityService.getRecommendations(
        userId: userId,
        region: region,
        city: city,
        category: category,
        limit: limit,
      );
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка получения рекомендаций: $e');
      return [];
    }
  }

  /// Получение топ пользователей
  Future<List<Map<String, dynamic>>> getTopUsers({
    String? region,
    String? city,
    String? category,
    int limit = 10,
  }) async {
    try {
      return await _priorityService.getTopUsers(
        region: region,
        city: city,
        category: category,
        limit: limit,
      );
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка получения топ пользователей: $e');
      return [];
    }
  }

  /// Получение рекламы для отображения
  Future<List<Advertisement>> getAdvertisementsForDisplay({
    required AdPlacement placement,
    String? region,
    String? city,
    String? category,
    int limit = 3,
  }) async {
    try {
      return await _priorityService.getAdvertisementsForDisplay(
        placement: placement,
        region: region,
        city: city,
        category: category,
        limit: limit,
      );
    } catch (e) {
      debugPrint('ERROR: [monetization_provider] Ошибка получения рекламы: $e');
      return [];
    }
  }

  /// Обновление данных
  Future<void> refresh(String userId) async {
    await loadMonetizationData(userId);
  }

  /// Очистка данных
  void clear() {
    _subscriptionPlans.clear();
    _promotionPackages.clear();
    _adCampaigns.clear();
    _advertisements.clear();
    _activeSubscription = null;
    _activePromotions.clear();
    _activeAdvertisements.clear();
    _stats.clear();
    _userPriority = 0;
    _userTier = SubscriptionTier.free;
    _clearError();
    notifyListeners();
  }

  // Приватные методы
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
