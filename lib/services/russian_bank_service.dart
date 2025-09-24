import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import '../models/payment_models.dart';

class RussianBankService {
  static const String _sbpBaseUrl = 'https://api.sbp.nspk.ru';
  static const String _yookassaBaseUrl = 'https://api.yookassa.ru/v3';
  static const String _tinkoffBaseUrl = 'https://securepay.tinkoff.ru/v2';

  // SBP (Система быстрых платежей) Integration
  Future<SbpPaymentResponse> createSbpPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
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
          'payment_id': paymentId,
        },
      };

      final response = await http.post(
        Uri.parse('$_sbpBaseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_getSbpApiKey()}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SbpPaymentResponse.fromMap(data);
      } else {
        throw Exception('SBP payment creation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating SBP payment: $e');
      throw Exception('Ошибка создания платежа СБП: $e');
    }
  }

  Future<SbpPaymentStatus> getSbpPaymentStatus(String externalPaymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_sbpBaseUrl/payments/$externalPaymentId'),
        headers: {
          'Authorization': 'Bearer ${_getSbpApiKey()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SbpPaymentStatus.fromMap(data);
      } else {
        throw Exception('Failed to get SBP payment status: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting SBP payment status: $e');
      throw Exception('Ошибка получения статуса платежа СБП: $e');
    }
  }

  // YooKassa Integration
  Future<YooKassaPaymentResponse> createYooKassaPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
    required PaymentMethod method,
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
          'payment_id': paymentId,
        },
        'payment_method_data': _getPaymentMethodData(method),
      };

      final response = await http.post(
        Uri.parse('$_yookassaBaseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${_getYooKassaAuth()}',
          'Idempotence-Key': paymentId,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return YooKassaPaymentResponse.fromMap(data);
      } else {
        throw Exception('YooKassa payment creation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating YooKassa payment: $e');
      throw Exception('Ошибка создания платежа ЮKassa: $e');
    }
  }

  Future<YooKassaPaymentStatus> getYooKassaPaymentStatus(String externalPaymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_yookassaBaseUrl/payments/$externalPaymentId'),
        headers: {
          'Authorization': 'Basic ${_getYooKassaAuth()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return YooKassaPaymentStatus.fromMap(data);
      } else {
        throw Exception('Failed to get YooKassa payment status: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting YooKassa payment status: $e');
      throw Exception('Ошибка получения статуса платежа ЮKassa: $e');
    }
  }

  // Tinkoff Pay Integration
  Future<TinkoffPaymentResponse> createTinkoffPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
  }) async {
    try {
      final requestBody = {
        'Amount': (amount * 100).toInt(), // Tinkoff expects amount in kopecks
        'OrderId': paymentId,
        'Description': description,
        'ReturnURL': returnUrl,
        'DATA': {
          'payment_id': paymentId,
        },
      };

      // Add signature for Tinkoff
      final signature = _generateTinkoffSignature(requestBody);
      requestBody['Token'] = signature;

      final response = await http.post(
        Uri.parse('$_tinkoffBaseUrl/Init'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TinkoffPaymentResponse.fromMap(data);
      } else {
        throw Exception('Tinkoff payment creation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating Tinkoff payment: $e');
      throw Exception('Ошибка создания платежа Tinkoff: $e');
    }
  }

  Future<TinkoffPaymentStatus> getTinkoffPaymentStatus(String externalPaymentId) async {
    try {
      final requestBody = {
        'PaymentId': externalPaymentId,
      };

      final signature = _generateTinkoffSignature(requestBody);
      requestBody['Token'] = signature;

      final response = await http.post(
        Uri.parse('$_tinkoffBaseUrl/GetState'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TinkoffPaymentStatus.fromMap(data);
      } else {
        throw Exception('Failed to get Tinkoff payment status: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting Tinkoff payment status: $e');
      throw Exception('Ошибка получения статуса платежа Tinkoff: $e');
    }
  }

  // Refund methods
  Future<RefundResponse> processRefund({
    required String externalPaymentId,
    required double amount,
    required PaymentMethod method,
    required String reason,
  }) async {
    try {
      switch (method) {
        case PaymentMethod.sbp:
          return await _processSbpRefund(externalPaymentId, amount, reason);
        case PaymentMethod.yookassa:
          return await _processYooKassaRefund(externalPaymentId, amount, reason);
        case PaymentMethod.tinkoff:
          return await _processTinkoffRefund(externalPaymentId, amount, reason);
        default:
          throw Exception('Refund not supported for method: $method');
      }
    } catch (e) {
      debugPrint('Error processing refund: $e');
      throw Exception('Ошибка обработки возврата: $e');
    }
  }

  Future<RefundResponse> _processSbpRefund(String externalPaymentId, double amount, String reason) async {
    // SBP refund implementation
    final requestBody = {
      'amount': {
        'value': amount.toStringAsFixed(2),
        'currency': 'RUB',
      },
      'payment_id': externalPaymentId,
      'description': reason,
    };

    final response = await http.post(
      Uri.parse('$_sbpBaseUrl/refunds'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getSbpApiKey()}',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RefundResponse.fromMap(data);
    } else {
      throw Exception('SBP refund failed: ${response.body}');
    }
  }

  Future<RefundResponse> _processYooKassaRefund(String externalPaymentId, double amount, String reason) async {
    final requestBody = {
      'amount': {
        'value': amount.toStringAsFixed(2),
        'currency': 'RUB',
      },
      'payment_id': externalPaymentId,
      'description': reason,
    };

    final response = await http.post(
      Uri.parse('$_yookassaBaseUrl/refunds'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${_getYooKassaAuth()}',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RefundResponse.fromMap(data);
    } else {
      throw Exception('YooKassa refund failed: ${response.body}');
    }
  }

  Future<RefundResponse> _processTinkoffRefund(String externalPaymentId, double amount, String reason) async {
    final requestBody = {
      'PaymentId': externalPaymentId,
      'Amount': (amount * 100).toInt(),
      'Description': reason,
    };

    final signature = _generateTinkoffSignature(requestBody);
    requestBody['Token'] = signature;

    final response = await http.post(
      Uri.parse('$_tinkoffBaseUrl/Cancel'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RefundResponse.fromMap(data);
    } else {
      throw Exception('Tinkoff refund failed: ${response.body}');
    }
  }

  // Helper methods
  String _getSbpApiKey() {
    // In production, get from secure storage or environment variables
    return 'your_sbp_api_key';
  }

  String _getYooKassaAuth() {
    // In production, get from secure storage or environment variables
    final shopId = 'your_shop_id';
    final secretKey = 'your_secret_key';
    return base64Encode(utf8.encode('$shopId:$secretKey'));
  }

  String _getTinkoffTerminalKey() {
    // In production, get from secure storage or environment variables
    return 'your_terminal_key';
  }

  String _getTinkoffPassword() {
    // In production, get from secure storage or environment variables
    return 'your_password';
  }

  String _generateTinkoffSignature(Map<String, dynamic> requestBody) {
    final terminalKey = _getTinkoffTerminalKey();
    final password = _getTinkoffPassword();
    
    // Create signature string
    final signatureString = '${requestBody['Amount']}${requestBody['OrderId']}$terminalKey$password';
    final bytes = utf8.encode(signatureString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  Map<String, dynamic> _getPaymentMethodData(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return {'type': 'bank_card'};
      case PaymentMethod.sbp:
        return {'type': 'sbp'};
      case PaymentMethod.yookassa:
        return {'type': 'yoo_money'};
      default:
        return {'type': 'bank_card'};
    }
  }

  // Get available payment methods
  List<PaymentMethodInfo> getAvailablePaymentMethods() {
    return [
      PaymentMethodInfo(
        method: PaymentMethod.sbp,
        name: 'СБП',
        description: 'Система быстрых платежей',
        iconUrl: 'assets/icons/sbp.png',
        isAvailable: true,
        fee: 0.0,
      ),
      PaymentMethodInfo(
        method: PaymentMethod.yookassa,
        name: 'ЮKassa',
        description: 'Банковские карты и электронные кошельки',
        iconUrl: 'assets/icons/yookassa.png',
        isAvailable: true,
        fee: 0.03, // 3% fee
      ),
      PaymentMethodInfo(
        method: PaymentMethod.tinkoff,
        name: 'Tinkoff Pay',
        description: 'Платежи через Tinkoff',
        iconUrl: 'assets/icons/tinkoff.png',
        isAvailable: true,
        fee: 0.025, // 2.5% fee
      ),
      PaymentMethodInfo(
        method: PaymentMethod.card,
        name: 'Банковская карта',
        description: 'Оплата банковской картой',
        iconUrl: 'assets/icons/card.png',
        isAvailable: true,
        fee: 0.035, // 3.5% fee
      ),
    ];
  }
}

// Response models
class SbpPaymentResponse {
  final String id;
  final String status;
  final String confirmationUrl;
  final String? qrCode;

  SbpPaymentResponse({
    required this.id,
    required this.status,
    required this.confirmationUrl,
    this.qrCode,
  });

  factory SbpPaymentResponse.fromMap(Map<String, dynamic> map) {
    return SbpPaymentResponse(
      id: map['id'] as String,
      status: map['status'] as String,
      confirmationUrl: map['confirmation']['confirmation_url'] as String,
      qrCode: map['confirmation']['qr_code'] as String?,
    );
  }
}

class SbpPaymentStatus {
  final String id;
  final String status;
  final bool paid;

  SbpPaymentStatus({
    required this.id,
    required this.status,
    required this.paid,
  });

  factory SbpPaymentStatus.fromMap(Map<String, dynamic> map) {
    return SbpPaymentStatus(
      id: map['id'] as String,
      status: map['status'] as String,
      paid: map['paid'] as bool,
    );
  }
}

class YooKassaPaymentResponse {
  final String id;
  final String status;
  final String confirmationUrl;
  final String? qrCode;

  YooKassaPaymentResponse({
    required this.id,
    required this.status,
    required this.confirmationUrl,
    this.qrCode,
  });

  factory YooKassaPaymentResponse.fromMap(Map<String, dynamic> map) {
    return YooKassaPaymentResponse(
      id: map['id'] as String,
      status: map['status'] as String,
      confirmationUrl: map['confirmation']['confirmation_url'] as String,
      qrCode: map['confirmation']['qr_code'] as String?,
    );
  }
}

class YooKassaPaymentStatus {
  final String id;
  final String status;
  final bool paid;

  YooKassaPaymentStatus({
    required this.id,
    required this.status,
    required this.paid,
  });

  factory YooKassaPaymentStatus.fromMap(Map<String, dynamic> map) {
    return YooKassaPaymentStatus(
      id: map['id'] as String,
      status: map['status'] as String,
      paid: map['paid'] as bool,
    );
  }
}

class TinkoffPaymentResponse {
  final String paymentId;
  final String status;
  final String paymentUrl;
  final String? qrCode;

  TinkoffPaymentResponse({
    required this.paymentId,
    required this.status,
    required this.paymentUrl,
    this.qrCode,
  });

  factory TinkoffPaymentResponse.fromMap(Map<String, dynamic> map) {
    return TinkoffPaymentResponse(
      paymentId: map['PaymentId'] as String,
      status: map['Status'] as String,
      paymentUrl: map['PaymentURL'] as String,
      qrCode: map['QRCode'] as String?,
    );
  }
}

class TinkoffPaymentStatus {
  final String paymentId;
  final String status;
  final bool success;

  TinkoffPaymentStatus({
    required this.paymentId,
    required this.status,
    required this.success,
  });

  factory TinkoffPaymentStatus.fromMap(Map<String, dynamic> map) {
    return TinkoffPaymentStatus(
      paymentId: map['PaymentId'] as String,
      status: map['Status'] as String,
      success: map['Success'] as bool,
    );
  }
}

class RefundResponse {
  final String id;
  final String status;
  final double amount;
  final String? reason;

  RefundResponse({
    required this.id,
    required this.status,
    required this.amount,
    this.reason,
  });

  factory RefundResponse.fromMap(Map<String, dynamic> map) {
    return RefundResponse(
      id: map['id'] as String,
      status: map['status'] as String,
      amount: (map['amount']['value'] as num).toDouble(),
      reason: map['reason'] as String?,
    );
  }
}
