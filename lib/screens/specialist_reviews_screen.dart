import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../models/review.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist.dart';
import 'package:flutter/foundation.dart';
import '../services/review_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/rating_summary_widget.dart';
import 'package:flutter/foundation.dart';
import '../widgets/review_card.dart';
import 'package:flutter/foundation.dart';

/// Р­РєСЂР°РЅ РѕС‚Р·С‹РІРѕРІ СЃРїРµС†РёР°Р»РёСЃС‚Р°
class SpecialistReviewsScreen extends StatefulWidget {
  const SpecialistReviewsScreen({
    super.key,
    required this.specialist,
  });
  final Specialist specialist;

  @override
  State<SpecialistReviewsScreen> createState() => _SpecialistReviewsScreenState();
}

class _SpecialistReviewsScreenState extends State<SpecialistReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadStats();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);

      final reviews = await _reviewService.getSpecialistReviews(
        widget.specialist.id,
      );

      setState(() {
        _reviews = reviews;
        _isLoading = false;
        _hasMore = reviews.length == 20;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РѕС‚Р·С‹РІРѕРІ: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _reviewService.getSpecialistReviewStats(widget.specialist.id);
      setState(() => _stats = stats);
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СЃС‚Р°С‚РёСЃС‚РёРєРё: $e');
    }
  }

  Future<void> _loadMoreReviews() async {
    if (!_hasMore || _isLoading) return;

    try {
      setState(() => _isLoading = true);

      final moreReviews = await _reviewService.getSpecialistReviews(
        widget.specialist.id,
        lastDocument: _lastDocument,
      );

      setState(() {
        _reviews.addAll(moreReviews);
        _isLoading = false;
        _hasMore = moreReviews.length == 20;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РѕС‚Р·С‹РІРѕРІ: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('РћС‚Р·С‹РІС‹ ${widget.specialist.name}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: _isLoading && _reviews.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // РЎРІРѕРґРєР° РїРѕ СЂРµР№С‚РёРЅРіСѓ
                  if (_stats.isNotEmpty)
                    RatingSummaryWidget(
                      averageRating: _stats['averageRating']?.toDouble() ?? 0.0,
                      totalReviews: _stats['totalReviews'] ?? 0,
                      ratingDistribution: Map<int, int>.from(
                        _stats['ratingDistribution'] ?? {},
                      ),
                    ),

                  // РЎРїРёСЃРѕРє РѕС‚Р·С‹РІРѕРІ
                  Expanded(
                    child: _reviews.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadReviews,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reviews.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _reviews.length) {
                                  // РљРЅРѕРїРєР° "Р—Р°РіСЂСѓР·РёС‚СЊ РµС‰Рµ"
                                  return _buildLoadMoreButton();
                                }

                                final review = _reviews[index];
                                return ReviewCard(
                                  review: review,
                                  showSpecialistInfo: false,
                                  onEdit: review.canEdit ? () => _editReview(review) : null,
                                  onDelete: review.canDelete ? () => _deleteReview(review) : null,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'РџРѕРєР° РЅРµС‚ РѕС‚Р·С‹РІРѕРІ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'РЎС‚Р°РЅСЊС‚Рµ РїРµСЂРІС‹Рј, РєС‚Рѕ РѕСЃС‚Р°РІРёС‚ РѕС‚Р·С‹РІ РѕР± СЌС‚РѕРј СЃРїРµС†РёР°Р»РёСЃС‚Рµ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLoadMoreButton() => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _loadMoreReviews,
                  child: const Text('Р—Р°РіСЂСѓР·РёС‚СЊ РµС‰Рµ'),
                ),
        ),
      );

  void _editReview(Review review) {
    // TODO(developer): РџРµСЂРµС…РѕРґ Рє СЌРєСЂР°РЅСѓ СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ РѕС‚Р·С‹РІР°
    context.push('/edit-review', extra: review);
  }

  void _deleteReview(Review review) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('РЈРґР°Р»РёС‚СЊ РѕС‚Р·С‹РІ'),
        content: const Text('Р’С‹ СѓРІРµСЂРµРЅС‹, С‡С‚Рѕ С…РѕС‚РёС‚Рµ СѓРґР°Р»РёС‚СЊ СЌС‚РѕС‚ РѕС‚Р·С‹РІ?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('РћС‚РјРµРЅР°'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              try {
                await _reviewService.deleteReview(review.id);
                _loadReviews();
                _loadStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('РћС‚Р·С‹РІ СѓРґР°Р»РµРЅ')),
                );
              } on Exception catch (e) {
                _showErrorSnackBar('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РѕС‚Р·С‹РІР°: $e');
              }
            },
            child: const Text('РЈРґР°Р»РёС‚СЊ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

