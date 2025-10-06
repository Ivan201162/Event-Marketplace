import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class YooKassaPaymentService {
  static const String _baseUrl =
      'https://api.yookassa.ru/v3'; // YooKassa API base URL
  static const String _shopId = 'YOUR_SHOP_ID'; // Replace with actual shop ID
  static const String _secretKey =
      'YOUR_SECRET_KEY'; // Replace with actual secret key

  /// Creates a payment request for YooKassa
  Future<YooKassaPaymentResponse> createPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
    required String customerId,
  }) async {
    try {
      final requestBody = {
        'amount': {
          'value': amount.toStringAsFixed(2),
          'currency': 'RUB',
        },
        'confirmation': {
          'type': 'redirect',
          'return_url': returnUrl,
        },
        'description': description,
        'metadata': {
          'paymentId': paymentId,
          'customerId': customerId,
        },
        'receipt': {
          'customer': {
            'email': 'customer@example.com', // Get from customer profile
          },
          'items': [
            {
              'description': description,
              'amount': {
                'value': amount.toStringAsFixed(2),
                'currency': 'RUB',
              },
              'vat_code': 1, // 20% VAT
              'quantity': '1',
            },
          ],
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
          'Idempotence-Key': paymentId,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return YooKassaPaymentResponse.fromJson(responseData);
      } else {
        throw Exception(
          'YooKassa API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('YooKassa payment creation error: $e');
      throw Exception('Ошибка создания платежа YooKassa: $e');
    }
  }

  /// Gets payment status from YooKassa
  Future<YooKassaPaymentStatus> getPaymentStatus(
    String yooKassaPaymentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$yooKassaPaymentId'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return YooKassaPaymentStatus.fromJson(responseData);
      } else {
        throw Exception(
          'YooKassa API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('YooKassa payment status error: $e');
      throw Exception('Ошибка получения статуса платежа YooKassa: $e');
    }
  }

  /// Captures a payment (confirms it)
  Future<void> capturePayment(String yooKassaPaymentId, double amount) async {
    try {
      final requestBody = {
        'amount': {
          'value': amount.toStringAsFixed(2),
          'currency': 'RUB',
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payments/$yooKassaPaymentId/capture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'YooKassa capture error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('YooKassa payment capture error: $e');
      throw Exception('Ошибка подтверждения платежа YooKassa: $e');
    }
  }

  /// Cancels a payment
  Future<void> cancelPayment(String yooKassaPaymentId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/$yooKassaPaymentId/cancel'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'YooKassa cancel error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('YooKassa payment cancel error: $e');
      throw Exception('Ошибка отмены платежа YooKassa: $e');
    }
  }

  /// Creates a refund
  Future<YooKassaRefundResponse> createRefund({
    required String yooKassaPaymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final requestBody = {
        'amount': {
          'value': amount.toStringAsFixed(2),
          'currency': 'RUB',
        },
        'payment_id': yooKassaPaymentId,
        'description': reason,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return YooKassaRefundResponse.fromJson(responseData);
      } else {
        throw Exception(
          'YooKassa refund error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('YooKassa refund creation error: $e');
      throw Exception('Ошибка создания возврата YooKassa: $e');
    }
  }

  /// Validates YooKassa webhook
  bool validateWebhook(Map<String, dynamic> webhookData) {
    try {
      // In real implementation, you would validate the signature
      // For now, we'll just check if required fields are present
      return webhookData.containsKey('type') &&
          webhookData.containsKey('event') &&
          webhookData.containsKey('object');
    } catch (e) {
      debugPrint('YooKassa webhook validation error: $e');
      return false;
    }
  }
}

/// YooKassa Payment Response
class YooKassaPaymentResponse {
  YooKassaPaymentResponse({
    required this.id,
    required this.status,
    required this.amount,
    this.confirmationUrl,
    this.description,
    required this.createdAt,
  });

  factory YooKassaPaymentResponse.fromJson(Map<String, dynamic> json) =>
      YooKassaPaymentResponse(
        id: json['id'] as String,
        status: json['status'] as String,
        amount: double.parse(json['amount']['value'] as String),
        confirmationUrl: json['confirmation']?['confirmation_url'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String status;
  final double amount;
  final String? confirmationUrl;
  final String? description;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'amount': {'value': amount.toStringAsFixed(2), 'currency': 'RUB'},
        'confirmation': confirmationUrl != null
            ? {'confirmation_url': confirmationUrl}
            : null,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}

/// YooKassa Payment Status
class YooKassaPaymentStatus {
  YooKassaPaymentStatus({
    required this.id,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.capturedAt,
    this.description,
  });

  factory YooKassaPaymentStatus.fromJson(Map<String, dynamic> json) =>
      YooKassaPaymentStatus(
        id: json['id'] as String,
        status: json['status'] as String,
        amount: double.parse(json['amount']['value'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        capturedAt: json['captured_at'] != null
            ? DateTime.parse(json['captured_at'] as String)
            : null,
        description: json['description'] as String?,
      );
  final String id;
  final String status;
  final double amount;
  final DateTime createdAt;
  final DateTime? capturedAt;
  final String? description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'amount': {'value': amount.toStringAsFixed(2), 'currency': 'RUB'},
        'created_at': createdAt.toIso8601String(),
        'captured_at': capturedAt?.toIso8601String(),
        'description': description,
      };

  bool get isCompleted => status == 'succeeded';
  bool get isFailed => status == 'canceled';
  bool get isPending => status == 'pending';
}

/// YooKassa Refund Response
class YooKassaRefundResponse {
  YooKassaRefundResponse({
    required this.id,
    required this.status,
    required this.amount,
    required this.paymentId,
    required this.createdAt,
  });

  factory YooKassaRefundResponse.fromJson(Map<String, dynamic> json) =>
      YooKassaRefundResponse(
        id: json['id'] as String,
        status: json['status'] as String,
        amount: double.parse(json['amount']['value'] as String),
        paymentId: json['payment_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String status;
  final double amount;
  final String paymentId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'amount': {'value': amount.toStringAsFixed(2), 'currency': 'RUB'},
        'payment_id': paymentId,
        'created_at': createdAt.toIso8601String(),
      };
}
