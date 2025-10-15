import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/booking.dart';
import '../models/contract.dart';
import '../models/specialist.dart';
import '../models/user.dart';
import '../models/work_act.dart';

/// Сервис для генерации PDF документов
class PdfService {
  /// Генерировать PDF договора
  Future<Uint8List> generateContractPdf(Contract contract) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Center(
                child: pw.Text(
                  'ДОГОВОР НА ОКАЗАНИЕ УСЛУГ',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Номер договора
              pw.Center(
                child: pw.Text(
                  '№ ${contract.contractNumber}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Дата и место
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('г. Москва'),
                  pw.Text(
                    '${contract.createdAt.day}.${contract.createdAt.month}.${contract.createdAt.year} г.',
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Содержание договора
              pw.Expanded(
                child: pw.Text(
                  contract.content,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),

              pw.SizedBox(height: 30),

              // Подписи
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Исполнитель:'),
                      pw.SizedBox(height: 20),
                      pw.Text('_________________'),
                      pw.Text(
                        '${contract.metadata['specialistName'] ?? 'Специалист'}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Заказчик:'),
                      pw.SizedBox(height: 20),
                      pw.Text('_________________'),
                      pw.Text(
                        '${contract.metadata['customerName'] ?? 'Заказчик'}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      return pdf.save();
    } on Exception catch (e) {
      throw Exception('Ошибка генерации PDF договора: $e');
    }
  }

  /// Генерировать PDF акта выполненных работ
  Future<Uint8List> generateWorkActPdf(WorkAct workAct) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Center(
                child: pw.Text(
                  'АКТ ВЫПОЛНЕННЫХ РАБОТ',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Номер акта
              pw.Center(
                child: pw.Text(
                  '№ ${workAct.actNumber}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Дата и место
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('г. Москва'),
                  pw.Text(
                    '${workAct.createdAt.day}.${workAct.createdAt.month}.${workAct.createdAt.year} г.',
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Информация о работах
              pw.Text(
                'Мы, нижеподписавшиеся, составили настоящий акт о том, что:',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                'Исполнитель: ${workAct.metadata['specialistName'] ?? 'Специалист'}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 5),

              pw.Text(
                'Заказчик: ${workAct.metadata['customerName'] ?? 'Заказчик'}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                'Выполнил следующие работы:',
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Описание работ
              pw.Text(
                workAct.workDescription ??
                    'Работы выполнены в соответствии с договором',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),

              // Стоимость
              pw.Text(
                'Стоимость выполненных работ: ${workAct.totalAmount.toStringAsFixed(2)} ${workAct.currency}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Период выполнения
              if (workAct.workStartDate != null && workAct.workEndDate != null)
                pw.Text(
                  'Период выполнения работ: с ${workAct.workStartDate!.day}.${workAct.workStartDate!.month}.${workAct.workStartDate!.year} по ${workAct.workEndDate!.day}.${workAct.workEndDate!.month}.${workAct.workEndDate!.year}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Работы выполнены в полном объеме, качественно и в установленные сроки.',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 30),

              // Подписи
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Исполнитель:'),
                      pw.SizedBox(height: 20),
                      pw.Text('_________________'),
                      pw.Text(
                        '${workAct.metadata['specialistName'] ?? 'Специалист'}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Заказчик:'),
                      pw.SizedBox(height: 20),
                      pw.Text('_________________'),
                      pw.Text(
                        '${workAct.metadata['customerName'] ?? 'Заказчик'}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      return pdf.save();
    } on Exception catch (e) {
      throw Exception('Ошибка генерации PDF акта: $e');
    }
  }

  /// Генерировать PDF счета
  Future<Uint8List> generateInvoicePdf({
    required Booking booking,
    required User customer,
    required Specialist specialist,
    required String invoiceNumber,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Center(
                child: pw.Text(
                  'СЧЕТ НА ОПЛАТУ',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Номер счета
              pw.Center(
                child: pw.Text(
                  '№ $invoiceNumber',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Дата
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Дата: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                  ),
                  pw.Text(
                    'Срок оплаты: ${DateTime.now().add(const Duration(days: 7)).day}.${DateTime.now().add(const Duration(days: 7)).month}.${DateTime.now().add(const Duration(days: 7)).year}',
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Поставщик
              pw.Text(
                'Поставщик:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(specialist.name),
              if (specialist.email != null)
                pw.Text('Email: ${specialist.email}'),
              if (specialist.phone != null)
                pw.Text('Телефон: ${specialist.phone}'),
              pw.SizedBox(height: 10),

              // Покупатель
              pw.Text(
                'Покупатель:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('${customer.name}'),
              if (customer.email != null) pw.Text('Email: ${customer.email}'),
              if (customer.phone != null) pw.Text('Телефон: ${customer.phone}'),
              pw.SizedBox(height: 20),

              // Таблица услуг
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Наименование услуги',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Количество',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Цена',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Сумма',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(booking.eventTitle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${booking.participantsCount}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${booking.totalPrice.toStringAsFixed(2)} ₽',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${booking.totalPrice.toStringAsFixed(2)} ₽',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Итого
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Итого: ${booking.totalPrice.toStringAsFixed(2)} ₽',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Подписи
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Поставщик:'),
                      pw.SizedBox(height: 20),
                      pw.Text('_________________'),
                      pw.Text(specialist.name),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Покупатель:'),
                      pw.SizedBox(height: 20),
                      pw.Text('_________________'),
                      pw.Text('${customer.name}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      return pdf.save();
    } on Exception catch (e) {
      throw Exception('Ошибка генерации PDF счета: $e');
    }
  }
}
