import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/payment_extended.dart';

/// Сервис для работы с расширенными платежами
class PaymentExtendedService {
  static final PaymentExtendedService _instance = PaymentExtendedService._internal();
  factory PaymentExtendedService() => _instance;
  PaymentExtendedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Создать новый платеж
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
      
      List<PaymentInstallment> installments = [];
      double paidAmount = 0.0;
      double remainingAmount = totalAmount;

      // Создаем рассрочку в зависимости от типа платежа
      switch (type) {
        case PaymentType.full:
          // Полная оплата - один платеж
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
          // Предоплата
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
          // Рассрочка
          final count = installmentsCount ?? 3;
          final installmentAmount = totalAmount / count;
          
          for (int i = 0; i < count; i++) {
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
          // Частичная оплата
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
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        status: PaymentStatus.pending,
        type: type,
        installments: installments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await paymentRef.set(payment.toMap());
      return paymentRef.id;
    } catch (e) {
      print('Ошибка создания платежа: $e');
      return null;
    }
  }

  /// Обновить платеж
  Future<bool> updatePayment(PaymentExtended payment) async {
    try {
      await _firestore.collection('payments').doc(payment.id).update(payment.toMap());
      return true;
    } catch (e) {
      print('Ошибка обновления платежа: $e');
      return false;
    }
  }

  /// Получить платеж по ID
  Future<PaymentExtended?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return PaymentExtended.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения платежа: $e');
      return null;
    }
  }

  /// Получить платежи пользователя
  Stream<List<PaymentExtended>> getUserPayments(String userId, {bool isCustomer = true}) {
    final field = isCustomer ? 'customerId' : 'specialistId';
    return _firestore
        .collection('payments')
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentExtended.fromDocument(doc))
          .toList();
    });
  }

  /// Оплатить взнос
  Future<bool> payInstallment({
    required String paymentId,
    required String installmentId,
    required String transactionId,
  }) async {
    try {
      final payment = await getPayment(paymentId);
      if (payment == null) return false;

      // Обновляем взнос
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

      // Пересчитываем суммы
      final paidAmount = updatedInstallments
          .where((i) => i.status == PaymentStatus.completed)
          .fold(0.0, (sum, i) => sum + i.amount);
      
      final remainingAmount = payment.totalAmount - paidAmount;
      final status = remainingAmount <= 0 ? PaymentStatus.completed : PaymentStatus.processing;

      // Обновляем платеж
      final updatedPayment = payment.copyWith(
        installments: updatedInstallments,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        status: status,
        updatedAt: DateTime.now(),
      );

      return await updatePayment(updatedPayment);
    } catch (e) {
      print('Ошибка оплаты взноса: $e');
      return false;
    }
  }

  /// Создать PDF квитанцию
  Future<String?> generateReceiptPdf(PaymentExtended payment) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Заголовок
                pw.Center(
                  child: pw.Text(
                    'КВИТАНЦИЯ ОБ ОПЛАТЕ',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Информация о платеже
                pw.Text('Номер платежа: ${payment.id}'),
                pw.Text('Дата создания: ${_formatDate(payment.createdAt)}'),
                pw.Text('Статус: ${_getStatusText(payment.status)}'),
                pw.SizedBox(height: 10),
                
                // Суммы
                pw.Text('Общая сумма: ${payment.totalAmount.toStringAsFixed(2)} ₽'),
                pw.Text('Оплачено: ${payment.paidAmount.toStringAsFixed(2)} ₽'),
                pw.Text('Остаток: ${payment.remainingAmount.toStringAsFixed(2)} ₽'),
                pw.SizedBox(height: 20),
                
                // Взносы
                pw.Text(
                  'Взносы:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                
                ...payment.installments.map((installment) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${_formatDate(installment.dueDate)}'),
                        pw.Text('${installment.amount.toStringAsFixed(2)} ₽'),
                        pw.Text(_getStatusText(installment.status)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      // Сохраняем PDF
      final bytes = await pdf.save();
      final fileName = 'receipt_${payment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('receipts/$fileName');
      
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Обновляем платеж с URL квитанции
      final updatedPayment = payment.copyWith(
        receiptPdfUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );
      await updatePayment(updatedPayment);

      return downloadUrl;
    } catch (e) {
      print('Ошибка создания PDF квитанции: $e');
      return null;
    }
  }

  /// Создать PDF счёт
  Future<String?> generateInvoicePdf(PaymentExtended payment) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Заголовок
                pw.Center(
                  child: pw.Text(
                    'СЧЁТ НА ОПЛАТУ',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Информация о счёте
                pw.Text('Номер счёта: ${payment.id}'),
                pw.Text('Дата создания: ${_formatDate(payment.createdAt)}'),
                pw.Text('Срок оплаты: ${_formatDate(DateTime.now().add(const Duration(days: 7)))}'),
                pw.SizedBox(height: 10),
                
                // Сумма к оплате
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'К ОПЛАТЕ: ${payment.remainingAmount.toStringAsFixed(2)} ₽',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Детали платежа
                pw.Text(
                  'Детали платежа:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                
                pw.Text('Общая сумма: ${payment.totalAmount.toStringAsFixed(2)} ₽'),
                pw.Text('Оплачено: ${payment.paidAmount.toStringAsFixed(2)} ₽'),
                pw.Text('Остаток: ${payment.remainingAmount.toStringAsFixed(2)} ₽'),
              ],
            );
          },
        ),
      );

      // Сохраняем PDF
      final bytes = await pdf.save();
      final fileName = 'invoice_${payment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('invoices/$fileName');
      
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Обновляем платеж с URL счёта
      final updatedPayment = payment.copyWith(
        invoicePdfUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );
      await updatePayment(updatedPayment);

      return downloadUrl;
    } catch (e) {
      print('Ошибка создания PDF счёта: $e');
      return null;
    }
  }

  /// Получить статистику платежей
  Future<PaymentStats> getPaymentStats(String userId, {bool isCustomer = true}) async {
    try {
      final field = isCustomer ? 'customerId' : 'specialistId';
      final snapshot = await _firestore
          .collection('payments')
          .where(field, isEqualTo: userId)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentExtended.fromDocument(doc))
          .toList();

      int totalPayments = payments.length;
      int completedPayments = payments.where((p) => p.status == PaymentStatus.completed).length;
      int pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).length;
      int failedPayments = payments.where((p) => p.status == PaymentStatus.failed).length;

      double totalAmount = payments.fold(0.0, (sum, p) => sum + p.totalAmount);
      double paidAmount = payments.fold(0.0, (sum, p) => sum + p.paidAmount);
      double pendingAmount = payments.fold(0.0, (sum, p) => sum + p.remainingAmount);

      Map<String, int> paymentsByType = {};
      Map<String, int> paymentsByStatus = {};

      for (final payment in payments) {
        paymentsByType[payment.type.name] = (paymentsByType[payment.type.name] ?? 0) + 1;
        paymentsByStatus[payment.status.name] = (paymentsByStatus[payment.status.name] ?? 0) + 1;
      }

      return PaymentStats(
        totalPayments: totalPayments,
        completedPayments: completedPayments,
        pendingPayments: pendingPayments,
        failedPayments: failedPayments,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        pendingAmount: pendingAmount,
        paymentsByType: paymentsByType,
        paymentsByStatus: paymentsByStatus,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Ошибка получения статистики: $e');
      return PaymentStats.empty();
    }
  }

  /// Получить настройки предоплаты
  Future<AdvancePaymentSettings> getAdvancePaymentSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('advance_payment').get();
      if (doc.exists) {
        return AdvancePaymentSettings.fromMap(doc.data()!);
      }
      return const AdvancePaymentSettings();
    } catch (e) {
      print('Ошибка получения настроек: $e');
      return const AdvancePaymentSettings();
    }
  }

  /// Обновить настройки предоплаты
  Future<bool> updateAdvancePaymentSettings(AdvancePaymentSettings settings) async {
    try {
      await _firestore.collection('settings').doc('advance_payment').set(settings.toMap());
      return true;
    } catch (e) {
      print('Ошибка обновления настроек: $e');
      return false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
      case PaymentStatus.processing:
        return 'В обработке';
      case PaymentStatus.completed:
        return 'Оплачено';
      case PaymentStatus.failed:
        return 'Ошибка';
      case PaymentStatus.cancelled:
        return 'Отменено';
      case PaymentStatus.refunded:
        return 'Возвращено';
    }
  }
}
