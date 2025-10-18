import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/payment_extended.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ СЂР°СЃС€РёСЂРµРЅРЅС‹РјРё РїР»Р°С‚РµР¶Р°РјРё
class PaymentExtendedService {
  factory PaymentExtendedService() => _instance;
  PaymentExtendedService._internal();
  static final PaymentExtendedService _instance = PaymentExtendedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;

  /// РЎРѕР·РґР°С‚СЊ РЅРѕРІС‹Р№ РїР»Р°С‚РµР¶
  Future<String?> createPayment({
    required String bookingId,
    required String customerId,
    required String specialistId,
    required double totalAmount,
    required PaymentType type,
    double? advancePercentage,
    int? installmentsCount,
  }) async {
    try {
      final paymentRef = _firestore.collection('payments').doc();

      var installments = <PaymentInstallment>[];
      const paidAmount = 0;
      final remainingAmount = totalAmount;

      // РЎРѕР·РґР°РµРј СЂР°СЃСЃСЂРѕС‡РєСѓ РІ Р·Р°РІРёСЃРёРјРѕСЃС‚Рё РѕС‚ С‚РёРїР° РїР»Р°С‚РµР¶Р°
      switch (type) {
        case PaymentType.full:
          // РџРѕР»РЅР°СЏ РѕРїР»Р°С‚Р° - РѕРґРёРЅ РїР»Р°С‚РµР¶
          installments = [
            PaymentInstallment(
              id: '${paymentRef.id}_1',
              amount: totalAmount,
              dueDate: DateTime.now().add(const Duration(days: 7)),
              status: PaymentStatus.pending,
            ),
          ];
          break;

        case PaymentType.advance:
          // РџСЂРµРґРѕРїР»Р°С‚Р°
          final advanceAmount = totalAmount * (advancePercentage ?? 0.3);
          final remainingAfterAdvance = totalAmount - advanceAmount;

          installments = [
            PaymentInstallment(
              id: '${paymentRef.id}_advance',
              amount: advanceAmount,
              dueDate: DateTime.now().add(const Duration(days: 3)),
              status: PaymentStatus.pending,
            ),
          ];

          if (remainingAfterAdvance > 0) {
            installments.add(
              PaymentInstallment(
                id: '${paymentRef.id}_final',
                amount: remainingAfterAdvance,
                dueDate: DateTime.now().add(const Duration(days: 30)),
                status: PaymentStatus.pending,
              ),
            );
          }
          break;

        case PaymentType.installment:
          // Р Р°СЃСЃСЂРѕС‡РєР°
          final count = installmentsCount ?? 3;
          final installmentAmount = totalAmount / count;

          for (var i = 0; i < count; i++) {
            installments.add(
              PaymentInstallment(
                id: '${paymentRef.id}_${i + 1}',
                amount: installmentAmount,
                dueDate: DateTime.now().add(Duration(days: (i + 1) * 30)),
                status: PaymentStatus.pending,
              ),
            );
          }
          break;

        case PaymentType.partial:
          // Р§Р°СЃС‚РёС‡РЅР°СЏ РѕРїР»Р°С‚Р°
          final partialAmount = totalAmount * 0.5;
          installments = [
            PaymentInstallment(
              id: '${paymentRef.id}_partial',
              amount: partialAmount,
              dueDate: DateTime.now().add(const Duration(days: 7)),
              status: PaymentStatus.pending,
            ),
            PaymentInstallment(
              id: '${paymentRef.id}_remaining',
              amount: totalAmount - partialAmount,
              dueDate: DateTime.now().add(const Duration(days: 30)),
              status: PaymentStatus.pending,
            ),
          ];
          break;
      }

      final payment = PaymentExtended(
        id: paymentRef.id,
        bookingId: bookingId,
        customerId: customerId,
        specialistId: specialistId,
        totalAmount: totalAmount.toDouble(),
        paidAmount: paidAmount.toDouble(),
        remainingAmount: remainingAmount.toDouble(),
        status: PaymentStatus.pending,
        type: type,
        installments: installments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await paymentRef.set(payment.toMap());
      return paymentRef.id;
    } on Exception {
      // TODO(developer): Log error properly
      return null;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РїР»Р°С‚РµР¶
  Future<bool> updatePayment(PaymentExtended payment) async {
    try {
      await _firestore.collection('payments').doc(payment.id).update(payment.toMap());
      return true;
    } on Exception {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїР»Р°С‚РµР¶ РїРѕ ID
  Future<PaymentExtended?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return PaymentExtended.fromDocument(doc);
      }
      return null;
    } on Exception {
      // TODO(developer): Log error properly
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РїР»Р°С‚РµР¶Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<List<PaymentExtended>> getUserPayments(
    String userId, {
    bool isCustomer = true,
  }) {
    final field = isCustomer ? 'customerId' : 'specialistId';
    return _firestore
        .collection('payments')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PaymentExtended.fromDocument).toList(),
        );
  }

  /// РћРїР»Р°С‚РёС‚СЊ РІР·РЅРѕСЃ
  Future<bool> payInstallment({
    required String paymentId,
    required String installmentId,
    required String transactionId,
  }) async {
    try {
      final payment = await getPayment(paymentId);
      if (payment == null) return false;

      // РћР±РЅРѕРІР»СЏРµРј РІР·РЅРѕСЃ
      final updatedInstallments = payment.installments.map((installment) {
        if (installment.id == installmentId) {
          return installment.copyWith(
            status: PaymentStatus.completed,
            paidAt: DateTime.now(),
            transactionId: transactionId,
          );
        }
        return installment;
      }).toList();

      // РџРµСЂРµСЃС‡РёС‚С‹РІР°РµРј СЃСѓРјРјС‹
      final paidAmount = updatedInstallments
          .where((i) => i.status == PaymentStatus.completed)
          .fold(0, (total, i) => total + i.amount);

      final remainingAmount = payment.totalAmount - paidAmount;
      final status = remainingAmount <= 0 ? PaymentStatus.completed : PaymentStatus.processing;

      // РћР±РЅРѕРІР»СЏРµРј РїР»Р°С‚РµР¶
      final updatedPayment = payment.copyWith(
        installments: updatedInstallments,
        paidAmount: paidAmount.toDouble(),
        remainingAmount: remainingAmount,
        status: status,
        updatedAt: DateTime.now(),
      );

      return await updatePayment(updatedPayment);
    } on Exception {
      // TODO(developer): Log error properly
      return false;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ PDF РєРІРёС‚Р°РЅС†РёСЋ
  Future<String?> generateReceiptPdf(PaymentExtended payment) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Р—Р°РіРѕР»РѕРІРѕРє
              pw.Center(
                child: pw.Text(
                  'РљР’РРўРђРќР¦РРЇ РћР‘ РћРџР›РђРўР•',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // РРЅС„РѕСЂРјР°С†РёСЏ Рѕ РїР»Р°С‚РµР¶Рµ
              pw.Text('РќРѕРјРµСЂ РїР»Р°С‚РµР¶Р°: ${payment.id}'),
              pw.Text('Р”Р°С‚Р° СЃРѕР·РґР°РЅРёСЏ: ${_formatDate(payment.createdAt)}'),
              pw.Text('РЎС‚Р°С‚СѓСЃ: ${_getStatusText(payment.status)}'),
              pw.SizedBox(height: 10),

              // РЎСѓРјРјС‹
              pw.Text(
                'РћР±С‰Р°СЏ СЃСѓРјРјР°: ${payment.totalAmount.toStringAsFixed(2)} в‚Ѕ',
              ),
              pw.Text('РћРїР»Р°С‡РµРЅРѕ: ${payment.paidAmount.toStringAsFixed(2)} в‚Ѕ'),
              pw.Text(
                'РћСЃС‚Р°С‚РѕРє: ${payment.remainingAmount.toStringAsFixed(2)} в‚Ѕ',
              ),
              pw.SizedBox(height: 20),

              // Р’Р·РЅРѕСЃС‹
              pw.Text(
                'Р’Р·РЅРѕСЃС‹:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              ...payment.installments.map(
                (installment) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(_formatDate(installment.dueDate)),
                      pw.Text('${installment.amount.toStringAsFixed(2)} в‚Ѕ'),
                      pw.Text(_getStatusText(installment.status)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // РЎРѕС…СЂР°РЅСЏРµРј PDF
      // final bytes = await pdf.save();
      final fileName = 'receipt_${payment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      // final ref = _storage.ref().child('receipts/$fileName');

      // final uploadTask = ref.putData(bytes);
      // final snapshot = await uploadTask;
      // final downloadUrl = await snapshot.ref.getDownloadURL();
      final downloadUrl = await _uploadReceipt(File(receiptPath));

      // РћР±РЅРѕРІР»СЏРµРј РїР»Р°С‚РµР¶ СЃ URL РєРІРёС‚Р°РЅС†РёРё
      final updatedPayment = payment.copyWith(
        receiptPdfUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );
      await updatePayment(updatedPayment);

      return downloadUrl;
    } on Exception {
      // TODO(developer): Log error properly
      return null;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ PDF СЃС‡С‘С‚
  Future<String?> generateInvoicePdf(PaymentExtended payment) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Р—Р°РіРѕР»РѕРІРѕРє
              pw.Center(
                child: pw.Text(
                  'РЎР§РЃРў РќРђ РћРџР›РђРўРЈ',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // РРЅС„РѕСЂРјР°С†РёСЏ Рѕ СЃС‡С‘С‚Рµ
              pw.Text('РќРѕРјРµСЂ СЃС‡С‘С‚Р°: ${payment.id}'),
              pw.Text('Р”Р°С‚Р° СЃРѕР·РґР°РЅРёСЏ: ${_formatDate(payment.createdAt)}'),
              pw.Text(
                'РЎСЂРѕРє РѕРїР»Р°С‚С‹: ${_formatDate(DateTime.now().add(const Duration(days: 7)))}',
              ),
              pw.SizedBox(height: 10),

              // РЎСѓРјРјР° Рє РѕРїР»Р°С‚Рµ
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Рљ РћРџР›РђРўР•: ${payment.remainingAmount.toStringAsFixed(2)} в‚Ѕ',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Р”РµС‚Р°Р»Рё РїР»Р°С‚РµР¶Р°
              pw.Text(
                'Р”РµС‚Р°Р»Рё РїР»Р°С‚РµР¶Р°:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                'РћР±С‰Р°СЏ СЃСѓРјРјР°: ${payment.totalAmount.toStringAsFixed(2)} в‚Ѕ',
              ),
              pw.Text('РћРїР»Р°С‡РµРЅРѕ: ${payment.paidAmount.toStringAsFixed(2)} в‚Ѕ'),
              pw.Text(
                'РћСЃС‚Р°С‚РѕРє: ${payment.remainingAmount.toStringAsFixed(2)} в‚Ѕ',
              ),
            ],
          ),
        ),
      );

      // РЎРѕС…СЂР°РЅСЏРµРј PDF
      // final bytes = await pdf.save();
      final fileName = 'invoice_${payment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      // final ref = _storage.ref().child('invoices/$fileName');

      // final uploadTask = ref.putData(bytes);
      // final snapshot = await uploadTask;
      // final downloadUrl = await snapshot.ref.getDownloadURL();
      final downloadUrl = await _uploadInvoice(File(invoicePath));

      // РћР±РЅРѕРІР»СЏРµРј РїР»Р°С‚РµР¶ СЃ URL СЃС‡С‘С‚Р°
      final updatedPayment = payment.copyWith(
        invoicePdfUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );
      await updatePayment(updatedPayment);

      return downloadUrl;
    } on Exception {
      // TODO(developer): Log error properly
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ РїР»Р°С‚РµР¶РµР№
  Future<PaymentStats> getPaymentStats(
    String userId, {
    bool isCustomer = true,
  }) async {
    try {
      final field = isCustomer ? 'customerId' : 'specialistId';
      final snapshot =
          await _firestore.collection('payments').where(field, isEqualTo: userId).get();

      final payments = snapshot.docs.map(PaymentExtended.fromDocument).toList();

      final totalPayments = payments.length;
      final completedPayments = payments.where((p) => p.status == PaymentStatus.completed).length;
      final pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).length;
      final failedPayments = payments.where((p) => p.status == PaymentStatus.failed).length;

      final totalAmount = payments.fold(0, (total, p) => total + p.totalAmount);
      final paidAmount = payments.fold(0, (total, p) => total + p.paidAmount);
      final pendingAmount = payments.fold(0, (total, p) => total + p.remainingAmount);

      final paymentsByType = <String, int>{};
      final paymentsByStatus = <String, int>{};

      for (final payment in payments) {
        paymentsByType[payment.type.name] = (paymentsByType[payment.type.name] ?? 0) + 1;
        paymentsByStatus[payment.status.name] = (paymentsByStatus[payment.status.name] ?? 0) + 1;
      }

      return PaymentStats(
        totalPayments: totalPayments,
        completedPayments: completedPayments,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        totalAmount: totalAmount.toDouble(),
        paidAmount: paidAmount.toDouble(),
        pendingAmount: pendingAmount.toDouble(),
        paymentsByType: paymentsByType,
        paymentsByStatus: paymentsByStatus,
        lastUpdated: DateTime.now(),
      );
    } on Exception {
      // TODO(developer): Log error properly
      return PaymentStats.empty();
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РЅР°СЃС‚СЂРѕР№РєРё РїСЂРµРґРѕРїР»Р°С‚С‹
  Future<AdvancePaymentSettings> getAdvancePaymentSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('advance_payment').get();
      if (doc.exists) {
        return AdvancePaymentSettings.fromMap(doc.data()!);
      }
      return const AdvancePaymentSettings();
    } on Exception {
      // TODO(developer): Log error properly
      return const AdvancePaymentSettings();
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РЅР°СЃС‚СЂРѕР№РєРё РїСЂРµРґРѕРїР»Р°С‚С‹
  Future<bool> updateAdvancePaymentSettings(
    AdvancePaymentSettings settings,
  ) async {
    try {
      await _firestore.collection('settings').doc('advance_payment').set(settings.toMap());
      return true;
    } on Exception {
      // TODO(developer): Log error properly
      return false;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'РћР¶РёРґР°РµС‚ РѕРїР»Р°С‚С‹';
      case PaymentStatus.processing:
        return 'Р’ РѕР±СЂР°Р±РѕС‚РєРµ';
      case PaymentStatus.completed:
        return 'РћРїР»Р°С‡РµРЅРѕ';
      case PaymentStatus.failed:
        return 'РћС€РёР±РєР°';
      case PaymentStatus.cancelled:
        return 'РћС‚РјРµРЅРµРЅРѕ';
      case PaymentStatus.refunded:
        return 'Р’РѕР·РІСЂР°С‰РµРЅРѕ';
    }
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ РєРІРёС‚Р°РЅС†РёСЋ РІ Firebase Storage
  Future<String> _uploadReceipt(File receiptFile) async {
    try {
      // TODO(developer): Implement actual Firebase Storage upload
      // final ref = _storage.ref().child('receipts').child('${DateTime.now().millisecondsSinceEpoch}.pdf');
      // final uploadTask = ref.putFile(receiptFile);
      // final snapshot = await uploadTask;
      // final downloadUrl = await snapshot.ref.getDownloadURL();
      // return downloadUrl;

      // Р’СЂРµРјРµРЅРЅР°СЏ Р·Р°РіР»СѓС€РєР°
      return 'https://example.com/receipts/${DateTime.now().millisecondsSinceEpoch}.pdf';
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РєРІРёС‚Р°РЅС†РёРё: $e');
      rethrow;
    }
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ СЃС‡С‘С‚ РІ Firebase Storage
  Future<String> _uploadInvoice(File invoiceFile) async {
    try {
      // TODO(developer): Implement actual Firebase Storage upload
      // final ref = _storage.ref().child('invoices').child('${DateTime.now().millisecondsSinceEpoch}.pdf');
      // final uploadTask = ref.putFile(invoiceFile);
      // final snapshot = await uploadTask;
      // final downloadUrl = await snapshot.ref.getDownloadURL();
      // return downloadUrl;

      // Р’СЂРµРјРµРЅРЅР°СЏ Р·Р°РіР»СѓС€РєР°
      return 'https://example.com/invoices/${DateTime.now().millisecondsSinceEpoch}.pdf';
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё СЃС‡С‘С‚Р°: $e');
      rethrow;
    }
  }
}

