import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Сервис для работы с электронными подписями
class SignatureService {
  /// Создать подпись из виджета
  static Future<String> captureSignature(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      return base64Encode(pngBytes);
    } catch (e) {
      throw Exception('Ошибка создания подписи: $e');
    }
  }

  /// Создать цифровую подпись (упрощенная версия)
  static String createDigitalSignature({
    required String userId,
    required String documentId,
    required String timestamp,
    required String
        privateKey, // В реальном приложении это должен быть настоящий приватный ключ
  }) {
    // В реальном приложении здесь должна быть криптографическая подпись
    // Пока что создаем простую хеш-подпись
    final data = '$userId:$documentId:$timestamp:$privateKey';
    final bytes = utf8.encode(data);
    final digest = bytes.fold(0, (prev, element) => prev + element);
    return digest.toString();
  }

  /// Проверить подпись
  static bool verifySignature({
    required String signature,
    required String userId,
    required String documentId,
    required String timestamp,
    required String
        publicKey, // В реальном приложении это должен быть настоящий публичный ключ
  }) {
    try {
      // В реальном приложении здесь должна быть проверка криптографической подписи
      final expectedSignature = createDigitalSignature(
        userId: userId,
        documentId: documentId,
        timestamp: timestamp,
        privateKey:
            publicKey, // В реальном приложении это должно быть по-другому
      );

      return signature == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  /// Создать подпись для документа
  static Future<Map<String, dynamic>> signDocument({
    required String userId,
    required String userName,
    required String documentId,
    required String documentType, // 'contract' или 'work_act'
    GlobalKey? signatureKey,
    String? digitalSignature,
  }) async {
    try {
      String signature;
      String signatureType;

      if (signatureKey != null) {
        // Создаем подпись от руки
        signature = await captureSignature(signatureKey);
        signatureType = 'drawn';
      } else if (digitalSignature != null) {
        // Используем цифровую подпись
        signature = digitalSignature;
        signatureType = 'digital';
      } else {
        throw Exception(
            'Необходимо предоставить либо подпись от руки, либо цифровую подпись',);
      }

      return {
        'userId': userId,
        'userName': userName,
        'signature': signature,
        'signatureType': signatureType,
        'signedAt': DateTime.now().toIso8601String(),
        'documentId': documentId,
        'documentType': documentType,
      };
    } catch (e) {
      throw Exception('Ошибка создания подписи документа: $e');
    }
  }

  /// Получить информацию о подписи
  static Map<String, dynamic> getSignatureInfo(String signature) {
    try {
      // Пытаемся декодировать как base64 (подпись от руки)
      final bytes = base64Decode(signature);
      return {'type': 'drawn', 'size': bytes.length, 'format': 'PNG'};
    } catch (e) {
      // Если не base64, то это цифровая подпись
      return {'type': 'digital', 'size': signature.length, 'format': 'HASH'};
    }
  }

  /// Валидировать подпись
  static bool validateSignature(Map<String, dynamic> signatureData) {
    try {
      // Проверяем обязательные поля
      if (!signatureData.containsKey('userId') ||
          !signatureData.containsKey('userName') ||
          !signatureData.containsKey('signature') ||
          !signatureData.containsKey('signedAt')) {
        return false;
      }

      // Проверяем формат даты
      final signedAt = DateTime.tryParse(signatureData['signedAt'] as String);
      if (signedAt == null) {
        return false;
      }

      // Проверяем, что подпись не слишком старая (например, не старше 1 года)
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      if (signedAt.isBefore(oneYearAgo)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Виджет для создания подписи от руки
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.penColor,
    this.penWidth,
  });

  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? penColor;
  final double? penWidth;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset> _points = <Offset>[];
  final GlobalKey _signatureKey = GlobalKey();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: _signatureKey,
        child: Container(
          width: widget.width ?? 300,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(Offset.infinite);
              });
            },
            child: CustomPaint(
              painter: SignaturePainter(
                points: _points,
                penColor: widget.penColor ?? Colors.black,
                penWidth: widget.penWidth ?? 2.0,
              ),
            ),
          ),
        ),
      );

  /// Очистить подпись
  void clear() {
    setState(_points.clear);
  }

  /// Проверить, есть ли подпись
  bool get hasSignature => _points.isNotEmpty;

  /// Получить ключ для захвата изображения
  GlobalKey get signatureKey => _signatureKey;
}

/// Художник для отрисовки подписи
class SignaturePainter extends CustomPainter {
  const SignaturePainter(
      {required this.points, required this.penColor, required this.penWidth,});

  final List<Offset> points;
  final Color penColor;
  final double penWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = penWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.penColor != penColor ||
      oldDelegate.penWidth != penWidth;
}
