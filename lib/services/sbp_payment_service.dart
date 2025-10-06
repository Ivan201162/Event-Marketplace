import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SBPPaymentService {
  static const String _baseUrl = 'https://api.sbp.nspk.ru'; // SBP API base URL
  static const String _merchantId =
      'YOUR_MERCHANT_ID'; // Replace with actual merchant ID
  static const String _apiKey = 'YOUR_API_KEY'; // Replace with actual API key

  /// Creates a payment request for SBP
  Future<SBPaymentResponse> createPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
  }) async {
    try {
      final requestBody = {
        'merchantId': _merchantId,
        'paymentId': paymentId,
        'amount': (amount * 100).toInt(), // Amount in kopecks
        'currency': 'RUB',
        'description': description,
        'returnUrl': returnUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return SBPaymentResponse.fromJson(responseData);
      } else {
        throw Exception(
          'SBP API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('SBP payment creation error: $e');
      throw Exception('Ошибка создания платежа СБП: $e');
    }
  }

  /// Gets payment status from SBP
  Future<SBPaymentStatus> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return SBPaymentStatus.fromJson(responseData);
      } else {
        throw Exception(
          'SBP API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('SBP payment status error: $e');
      throw Exception('Ошибка получения статуса платежа СБП: $e');
    }
  }

  /// Generates QR code data for SBP payment
  String generateQRCodeData({
    required String paymentId,
    required double amount,
    required String description,
  }) {
    // SBP QR code format: sbp://payment?merchantId=...&paymentId=...&amount=...
    final qrData =
        'sbp://payment?merchantId=$_merchantId&paymentId=$paymentId&amount=${(amount * 100).toInt()}&description=${Uri.encodeComponent(description)}';
    return qrData;
  }

  /// Validates SBP payment callback
  bool validateCallback(Map<String, dynamic> callbackData) {
    try {
      // In real implementation, you would validate the signature
      // For now, we'll just check if required fields are present
      return callbackData.containsKey('paymentId') &&
          callbackData.containsKey('status') &&
          callbackData.containsKey('amount');
    } catch (e) {
      debugPrint('SBP callback validation error: $e');
      return false;
    }
  }
}

/// SBP Payment Response
class SBPaymentResponse {
  SBPaymentResponse({
    required this.paymentId,
    required this.qrCodeUrl,
    required this.paymentUrl,
    required this.status,
    this.errorMessage,
  });

  factory SBPaymentResponse.fromJson(Map<String, dynamic> json) =>
      SBPaymentResponse(
        paymentId: json['paymentId'] as String,
        qrCodeUrl: json['qrCodeUrl'] as String,
        paymentUrl: json['paymentUrl'] as String,
        status: json['status'] as String,
        errorMessage: json['errorMessage'] as String?,
      );
  final String paymentId;
  final String qrCodeUrl;
  final String paymentUrl;
  final String status;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'qrCodeUrl': qrCodeUrl,
        'paymentUrl': paymentUrl,
        'status': status,
        'errorMessage': errorMessage,
      };
}

/// SBP Payment Status
class SBPaymentStatus {
  SBPaymentStatus({
    required this.paymentId,
    required this.status,
    required this.amount,
    this.transactionId,
    this.completedAt,
    this.errorMessage,
  });

  factory SBPaymentStatus.fromJson(Map<String, dynamic> json) =>
      SBPaymentStatus(
        paymentId: json['paymentId'] as String,
        status: json['status'] as String,
        amount: (json['amount'] as int) / 100.0, // Convert from kopecks
        transactionId: json['transactionId'] as String?,
        completedAt: json['completedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
            : null,
        errorMessage: json['errorMessage'] as String?,
      );
  final String paymentId;
  final String status;
  final double amount;
  final String? transactionId;
  final DateTime? completedAt;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'status': status,
        'amount': (amount * 100).toInt(),
        'transactionId': transactionId,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'errorMessage': errorMessage,
      };

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isPending => status == 'PENDING';
}
