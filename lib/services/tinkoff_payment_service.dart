import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TinkoffPaymentService {
  static const String _baseUrl =
      'https://securepay.tinkoff.ru/v2'; // Tinkoff API base URL
  static const String _terminalKey =
      'YOUR_TERMINAL_KEY'; // Replace with actual terminal key
  static const String _password =
      'YOUR_PASSWORD'; // Replace with actual password

  /// Creates a payment request for Tinkoff
  Future<TinkoffPaymentResponse> createPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
    required String customerId,
  }) async {
    try {
      final requestBody = {
        'TerminalKey': _terminalKey,
        'Amount': (amount * 100).toInt(), // Amount in kopecks
        'OrderId': paymentId,
        'Description': description,
        'CustomerKey': customerId,
        'ReturnURL': returnUrl,
        'NotificationURL':
            'https://your-domain.com/tinkoff/notifications', // Replace with your webhook URL
        'Receipt': {
          'EmailCompany': 'noreply@eventmarketplace.com',
          'Taxation': 'osn', // General taxation system
          'Items': [
            {
              'Name': description,
              'Price': (amount * 100).toInt(),
              'Quantity': 1,
              'Amount': (amount * 100).toInt(),
              'Tax': 'vat20', // 20% VAT
            },
          ],
        },
      };

      // Add signature
      requestBody['Token'] = _generateToken(requestBody);

      final response = await http.post(
        Uri.parse('$_baseUrl/Init'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TinkoffPaymentResponse.fromJson(responseData);
      } else {
        throw Exception(
          'Tinkoff API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Tinkoff payment creation error: $e');
      throw Exception('Ошибка создания платежа Tinkoff: $e');
    }
  }

  /// Gets payment status from Tinkoff
  Future<TinkoffPaymentStatus> getPaymentStatus(String paymentId) async {
    try {
      final requestBody = {
        'TerminalKey': _terminalKey,
        'PaymentId': paymentId,
      };

      // Add signature
      requestBody['Token'] = _generateToken(requestBody);

      final response = await http.post(
        Uri.parse('$_baseUrl/GetState'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TinkoffPaymentStatus.fromJson(responseData);
      } else {
        throw Exception(
          'Tinkoff API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Tinkoff payment status error: $e');
      throw Exception('Ошибка получения статуса платежа Tinkoff: $e');
    }
  }

  /// Confirms a payment
  Future<void> confirmPayment(String paymentId, double amount) async {
    try {
      final requestBody = {
        'TerminalKey': _terminalKey,
        'PaymentId': paymentId,
        'Amount': (amount * 100).toInt(),
      };

      // Add signature
      requestBody['Token'] = _generateToken(requestBody);

      final response = await http.post(
        Uri.parse('$_baseUrl/Confirm'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Tinkoff confirm error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Tinkoff payment confirm error: $e');
      throw Exception('Ошибка подтверждения платежа Tinkoff: $e');
    }
  }

  /// Cancels a payment
  Future<void> cancelPayment(String paymentId) async {
    try {
      final requestBody = {
        'TerminalKey': _terminalKey,
        'PaymentId': paymentId,
      };

      // Add signature
      requestBody['Token'] = _generateToken(requestBody);

      final response = await http.post(
        Uri.parse('$_baseUrl/Cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Tinkoff cancel error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Tinkoff payment cancel error: $e');
      throw Exception('Ошибка отмены платежа Tinkoff: $e');
    }
  }

  /// Creates a refund
  Future<TinkoffRefundResponse> createRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final requestBody = {
        'TerminalKey': _terminalKey,
        'PaymentId': paymentId,
        'Amount': (amount * 100).toInt(),
        'Description': reason,
      };

      // Add signature
      requestBody['Token'] = _generateToken(requestBody);

      final response = await http.post(
        Uri.parse('$_baseUrl/Cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TinkoffRefundResponse.fromJson(responseData);
      } else {
        throw Exception(
          'Tinkoff refund error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Tinkoff refund creation error: $e');
      throw Exception('Ошибка создания возврата Tinkoff: $e');
    }
  }

  /// Generates token for Tinkoff API
  String _generateToken(Map<String, dynamic> requestBody) {
    // Remove Token field if it exists
    final cleanBody = Map<String, dynamic>.from(requestBody);
    cleanBody.remove('Token');

    // Sort keys alphabetically
    final sortedKeys = cleanBody.keys.toList()..sort();

    // Create string for hashing
    var dataString = '';
    for (final key in sortedKeys) {
      if (cleanBody[key] is Map) {
        // Handle nested objects (like Receipt)
        dataString += _flattenMap(cleanBody[key] as Map<String, dynamic>);
      } else {
        dataString += cleanBody[key].toString();
      }
    }

    dataString += _password;

    // Generate SHA-256 hash
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Flattens nested map for token generation
  String _flattenMap(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    var result = '';

    for (final key in sortedKeys) {
      if (map[key] is List) {
        // Handle arrays
        final list = map[key] as List;
        for (final item in list) {
          if (item is Map) {
            result += _flattenMap(item as Map<String, dynamic>);
          } else {
            result += item.toString();
          }
        }
      } else if (map[key] is Map) {
        result += _flattenMap(map[key] as Map<String, dynamic>);
      } else {
        result += map[key].toString();
      }
    }

    return result;
  }

  /// Validates Tinkoff webhook
  bool validateWebhook(Map<String, dynamic> webhookData) {
    try {
      // In real implementation, you would validate the signature
      // For now, we'll just check if required fields are present
      return webhookData.containsKey('TerminalKey') &&
          webhookData.containsKey('Status') &&
          webhookData.containsKey('PaymentId');
    } catch (e) {
      debugPrint('Tinkoff webhook validation error: $e');
      return false;
    }
  }
}

/// Tinkoff Payment Response
class TinkoffPaymentResponse {
  TinkoffPaymentResponse({
    required this.success,
    this.errorCode,
    this.message,
    this.details,
    this.terminalKey,
    this.status,
    this.paymentId,
    this.orderId,
    required this.amount,
    this.paymentUrl,
  });

  factory TinkoffPaymentResponse.fromJson(Map<String, dynamic> json) =>
      TinkoffPaymentResponse(
        success: json['Success'] as bool,
        errorCode: json['ErrorCode'] as String?,
        message: json['Message'] as String?,
        details: json['Details'] as String?,
        terminalKey: json['TerminalKey'] as String?,
        status: json['Status'] as String?,
        paymentId: json['PaymentId'] as String?,
        orderId: json['OrderId'] as String?,
        amount: json['Amount'] != null ? (json['Amount'] as int) / 100.0 : 0.0,
        paymentUrl: json['PaymentURL'] as String?,
      );
  final bool success;
  final String? errorCode;
  final String? message;
  final String? details;
  final String? terminalKey;
  final String? status;
  final String? paymentId;
  final String? orderId;
  final double amount;
  final String? paymentUrl;

  Map<String, dynamic> toJson() => {
        'Success': success,
        'ErrorCode': errorCode,
        'Message': message,
        'Details': details,
        'TerminalKey': terminalKey,
        'Status': status,
        'PaymentId': paymentId,
        'OrderId': orderId,
        'Amount': (amount * 100).toInt(),
        'PaymentURL': paymentUrl,
      };
}

/// Tinkoff Payment Status
class TinkoffPaymentStatus {
  TinkoffPaymentStatus({
    required this.success,
    this.errorCode,
    this.message,
    this.details,
    this.terminalKey,
    this.status,
    this.paymentId,
    this.orderId,
    required this.amount,
    this.created,
  });

  factory TinkoffPaymentStatus.fromJson(Map<String, dynamic> json) =>
      TinkoffPaymentStatus(
        success: json['Success'] as bool,
        errorCode: json['ErrorCode'] as String?,
        message: json['Message'] as String?,
        details: json['Details'] as String?,
        terminalKey: json['TerminalKey'] as String?,
        status: json['Status'] as String?,
        paymentId: json['PaymentId'] as String?,
        orderId: json['OrderId'] as String?,
        amount: json['Amount'] != null ? (json['Amount'] as int) / 100.0 : 0.0,
        created: json['Created'] != null
            ? DateTime.parse(json['Created'] as String)
            : null,
      );
  final bool success;
  final String? errorCode;
  final String? message;
  final String? details;
  final String? terminalKey;
  final String? status;
  final String? paymentId;
  final String? orderId;
  final double amount;
  final DateTime? created;

  Map<String, dynamic> toJson() => {
        'Success': success,
        'ErrorCode': errorCode,
        'Message': message,
        'Details': details,
        'TerminalKey': terminalKey,
        'Status': status,
        'PaymentId': paymentId,
        'OrderId': orderId,
        'Amount': (amount * 100).toInt(),
        'Created': created?.toIso8601String(),
      };

  bool get isCompleted => status == 'CONFIRMED';
  bool get isFailed => status == 'REJECTED' || status == 'CANCELED';
  bool get isPending =>
      status == 'NEW' ||
      status == 'FORM_SHOWED' ||
      status == 'DEADLINE_EXPIRED';
}

/// Tinkoff Refund Response
class TinkoffRefundResponse {
  TinkoffRefundResponse({
    required this.success,
    this.errorCode,
    this.message,
    this.details,
    this.terminalKey,
    this.status,
    this.paymentId,
    required this.amount,
  });

  factory TinkoffRefundResponse.fromJson(Map<String, dynamic> json) =>
      TinkoffRefundResponse(
        success: json['Success'] as bool,
        errorCode: json['ErrorCode'] as String?,
        message: json['Message'] as String?,
        details: json['Details'] as String?,
        terminalKey: json['TerminalKey'] as String?,
        status: json['Status'] as String?,
        paymentId: json['PaymentId'] as String?,
        amount: json['Amount'] != null ? (json['Amount'] as int) / 100.0 : 0.0,
      );
  final bool success;
  final String? errorCode;
  final String? message;
  final String? details;
  final String? terminalKey;
  final String? status;
  final String? paymentId;
  final double amount;

  Map<String, dynamic> toJson() => {
        'Success': success,
        'ErrorCode': errorCode,
        'Message': message,
        'Details': details,
        'TerminalKey': terminalKey,
        'Status': status,
        'PaymentId': paymentId,
        'Amount': (amount * 100).toInt(),
      };
}
