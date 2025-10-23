import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/admin_models.dart';
import '../models/subscription_plan.dart';
import 'admin_service.dart';

class MarketingAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final AdminService _adminService = AdminService();

  /// Управление тарифными планами
  Future<bool> createSubscriptionPlan({
    required SubscriptionPlan plan,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore
          .collection('subscription_plans')
          .doc(plan.id)
          .set(plan.toMap());

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.createSubscriptionPlan,
        target: 'subscription_plan',
        targetId: plan.id,
        description: 'Created subscription plan: ${plan.name}',
        metadata: {'planName': plan.name, 'price': plan.price},
      );

      debugPrint(
          'INFO: [MarketingAdminService] Subscription plan created: ${plan.name}');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to create subscription plan: $e');
      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.createSubscriptionPlan,
        target: 'subscription_plan',
        targetId: plan.id,
        description: 'Failed to create subscription plan: ${plan.name}',
        status: AdminActionStatus.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateSubscriptionPlan({
    required String planId,
    required Map<String, dynamic> updates,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore.collection('subscription_plans').doc(planId).update({
        ...updates,
        'updatedAt': DateTime.now(),
      });

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.updateSubscriptionPlan,
        target: 'subscription_plan',
        targetId: planId,
        description: 'Updated subscription plan: $planId',
        metadata: updates,
      );

      debugPrint(
          'INFO: [MarketingAdminService] Subscription plan updated: $planId');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to update subscription plan: $e');
      return false;
    }
  }

  /// Управление рекламными кампаниями
  Future<bool> createMarketingCampaign({
    required MarketingCampaign campaign,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore
          .collection('marketing_campaigns')
          .doc(campaign.id)
          .set(campaign.toMap());

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.createCampaign,
        target: 'marketing_campaign',
        targetId: campaign.id,
        description: 'Created marketing campaign: ${campaign.name}',
        metadata: {'campaignName': campaign.name, 'type': campaign.type.name},
      );

      debugPrint(
          'INFO: [MarketingAdminService] Marketing campaign created: ${campaign.name}');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to create marketing campaign: $e');
      return false;
    }
  }

  Future<bool> updateMarketingCampaign({
    required String campaignId,
    required Map<String, dynamic> updates,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore
          .collection('marketing_campaigns')
          .doc(campaignId)
          .update({
        ...updates,
        'updatedAt': DateTime.now(),
      });

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.updateCampaign,
        target: 'marketing_campaign',
        targetId: campaignId,
        description: 'Updated marketing campaign: $campaignId',
        metadata: updates,
      );

      debugPrint(
          'INFO: [MarketingAdminService] Marketing campaign updated: $campaignId');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to update marketing campaign: $e');
      return false;
    }
  }

  /// Управление рассылками
  Future<bool> createNewsletter({
    required MarketingNewsletter newsletter,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore
          .collection('marketing_newsletters')
          .doc(newsletter.id)
          .set(newsletter.toMap());

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.sendNotification,
        target: 'newsletter',
        targetId: newsletter.id,
        description: 'Created newsletter: ${newsletter.title}',
        metadata: {
          'newsletterTitle': newsletter.title,
          'type': newsletter.type.name
        },
      );

      debugPrint(
          'INFO: [MarketingAdminService] Newsletter created: ${newsletter.title}');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to create newsletter: $e');
      return false;
    }
  }

  Future<bool> sendNewsletter({
    required String newsletterId,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore
          .collection('marketing_newsletters')
          .doc(newsletterId)
          .update({
        'status': NewsletterStatus.sending.name,
        'sentAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.sendBulkNotification,
        target: 'newsletter',
        targetId: newsletterId,
        description: 'Sent newsletter: $newsletterId',
      );

      debugPrint(
          'INFO: [MarketingAdminService] Newsletter sent: $newsletterId');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to send newsletter: $e');
      return false;
    }
  }

  /// Получение статистики рефералов
  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final stats = <String, dynamic>{};

      // Общее количество рефералов
      final referralsSnapshot = await _firestore.collection('referrals').get();
      stats['totalReferrals'] = referralsSnapshot.docs.length;

      // Активные рефералы
      final activeReferralsSnapshot = await _firestore
          .collection('referrals')
          .where('status', isEqualTo: 'completed')
          .get();
      stats['activeReferrals'] = activeReferralsSnapshot.docs.length;

      // Статистика по месяцам
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      final thisMonthReferrals = await _firestore
          .collection('referrals')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
          .get();
      stats['thisMonthReferrals'] = thisMonthReferrals.docs.length;

      // Топ рефереры
      final referralStatsSnapshot = await _firestore
          .collection('referral_program_stats')
          .orderBy('invitedUsersCount', descending: true)
          .limit(10)
          .get();

      final topReferrers = <Map<String, dynamic>>[];
      for (final doc in referralStatsSnapshot.docs) {
        final data = doc.data();
        topReferrers.add({
          'userId': doc.id,
          'invitedCount': data['invitedUsersCount'] ?? 0,
          'bonusesActivated': data['activatedBonusesCount'] ?? 0,
        });
      }
      stats['topReferrers'] = topReferrers;

      return stats;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to get referral stats: $e');
      return {};
    }
  }

  /// Получение статистики партнёров
  Future<Map<String, dynamic>> getPartnerStats() async {
    try {
      final stats = <String, dynamic>{};

      // Общее количество партнёров
      final partnersSnapshot = await _firestore.collection('partners').get();
      stats['totalPartners'] = partnersSnapshot.docs.length;

      // Активные партнёры
      final activePartnersSnapshot = await _firestore
          .collection('partners')
          .where('isActive', isEqualTo: true)
          .get();
      stats['activePartners'] = activePartnersSnapshot.docs.length;

      // Общая сумма комиссий
      final partnerTransactionsSnapshot =
          await _firestore.collection('partner_transactions').get();
      double totalCommissions = 0.0;
      for (final doc in partnerTransactionsSnapshot.docs) {
        totalCommissions += (doc.data()['commissionAmount'] ?? 0.0).toDouble();
      }
      stats['totalCommissions'] = totalCommissions;

      // Топ партнёры по доходам
      final partnerEarnings = <String, double>{};
      for (final doc in partnerTransactionsSnapshot.docs) {
        final data = doc.data();
        final partnerId = data['partnerId'] ?? '';
        final commission = (data['commissionAmount'] ?? 0.0).toDouble();
        partnerEarnings[partnerId] =
            (partnerEarnings[partnerId] ?? 0.0) + commission;
      }

      final sortedPartners = partnerEarnings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      stats['topPartners'] = sortedPartners
          .take(10)
          .map(
              (entry) => {'partnerId': entry.key, 'totalEarnings': entry.value})
          .toList();

      return stats;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to get partner stats: $e');
      return {};
    }
  }

  /// Получение финансовой аналитики
  Future<List<FinancialAnalytics>> getFinancialAnalytics({
    required String period, // daily, weekly, monthly
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('financial_analytics');

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.where('period', isEqualTo: period);

      final snapshot = await query.orderBy('date', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              FinancialAnalytics.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to get financial analytics: $e');
      return [];
    }
  }

  /// Создание сегмента пользователей
  Future<bool> createUserSegment({
    required UserSegment segment,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      // Подсчет пользователей в сегменте
      final userCount = await _countUsersInSegment(segment.criteria);
      final segmentWithCount = UserSegment(
        id: segment.id,
        name: segment.name,
        description: segment.description,
        criteria: segment.criteria,
        userCount: userCount,
        createdAt: segment.createdAt,
        updatedAt: segment.updatedAt,
        createdBy: segment.createdBy,
      );

      await _firestore
          .collection('user_segments')
          .doc(segment.id)
          .set(segmentWithCount.toMap());

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: AdminAction.create,
        target: 'user_segment',
        targetId: segment.id,
        description: 'Created user segment: ${segment.name}',
        metadata: {'segmentName': segment.name, 'userCount': userCount},
      );

      debugPrint(
          'INFO: [MarketingAdminService] User segment created: ${segment.name}');
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to create user segment: $e');
      return false;
    }
  }

  /// Подсчет пользователей в сегменте
  Future<int> _countUsersInSegment(Map<String, dynamic> criteria) async {
    try {
      Query query = _firestore.collection('users');

      for (final entry in criteria.entries) {
        if (entry.value is Map) {
          final condition = entry.value as Map<String, dynamic>;
          if (condition.containsKey('gte')) {
            query = query.where(entry.key,
                isGreaterThanOrEqualTo: condition['gte']);
          } else if (condition.containsKey('lte')) {
            query =
                query.where(entry.key, isLessThanOrEqualTo: condition['lte']);
          } else if (condition.containsKey('in')) {
            query = query.where(entry.key, whereIn: condition['in']);
          }
        } else {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to count users in segment: $e');
      return 0;
    }
  }

  /// Получение всех маркетинговых кампаний
  Stream<List<MarketingCampaign>> getMarketingCampaignsStream() {
    return _firestore
        .collection('marketing_campaigns')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketingCampaign.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Получение всех рассылок
  Stream<List<MarketingNewsletter>> getNewslettersStream() {
    return _firestore
        .collection('marketing_newsletters')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MarketingNewsletter.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Получение всех сегментов пользователей
  Stream<List<UserSegment>> getUserSegmentsStream() {
    return _firestore
        .collection('user_segments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserSegment.fromMap(doc.data()))
            .toList());
  }

  /// Активация/деактивация кампании
  Future<bool> toggleCampaignStatus({
    required String campaignId,
    required MarketingCampaignStatus newStatus,
    required String adminId,
    required String adminEmail,
  }) async {
    try {
      await _firestore
          .collection('marketing_campaigns')
          .doc(campaignId)
          .update({
        'status': newStatus.name,
        'updatedAt': DateTime.now(),
      });

      await _adminService.logAdminAction(
        adminId: adminId,
        adminEmail: adminEmail,
        action: newStatus == MarketingCampaignStatus.active
            ? AdminAction.activate
            : AdminAction.deactivate,
        target: 'marketing_campaign',
        targetId: campaignId,
        description: 'Changed campaign status to ${newStatus.name}',
      );

      debugPrint(
        'INFO: [MarketingAdminService] Campaign status changed: $campaignId to ${newStatus.name}',
      );
      return true;
    } catch (e) {
      debugPrint(
          'ERROR: [MarketingAdminService] Failed to toggle campaign status: $e');
      return false;
    }
  }
}
