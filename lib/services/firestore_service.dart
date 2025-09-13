import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream: заявки по customerId
  Stream<List<Booking>> bookingsByCustomerStream(String customerId) {
    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Booking.fromDocument(d)).toList());
  }

  // Stream: заявки по specialistId
  Stream<List<Booking>> bookingsBySpecialistStream(String specialistId) {
    return _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Booking.fromDocument(d)).toList());
  }

  // Общий стрим всех заявок (для админов/отладки)
  Stream<List<Booking>> getAllBookingsStream() {
    return _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Booking.fromDocument(d)).toList());
  }

  // Добавить/обновить заявку
  Future<void> addOrUpdateBooking(Booking booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());
  }

  // Обновить статус
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({'status': status});
  }

  // Обновить платежный статус / аванс
  Future<void> updatePaymentStatus(String bookingId, {required bool prepaymentPaid, required String paymentStatus}) async {
    await _db.collection('bookings').doc(bookingId).update({
      'prepaymentPaid': prepaymentPaid,
      'paymentStatus': paymentStatus,
    });
  }

  // Получить занятые даты (confirmed) для календаря
  Future<List<DateTime>> getBusyDates(String specialistId) async {
    final qs = await _db
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: 'confirmed')
        .get();
    return qs.docs.map((d) => (d.data()['eventDate'] as Timestamp).toDate()).toList();
  }

  // Добавить тестовые заявки (для локального теста)
  Future<void> addTestBookings() async {
    final now = DateTime.now();
    final b1 = Booking(
      id: 'b_test_1',
      customerId: 'u_customer1',
      specialistId: 's1',
      eventDate: now.add(const Duration(days: 7)),
      status: 'pending',
      prepayment: 3000,
      totalPrice: 10000,
    );
    final b2 = Booking(
      id: 'b_test_2',
      customerId: 'u_customer2',
      specialistId: 's1',
      eventDate: now.add(const Duration(days: 14)),
      status: 'confirmed',
      prepayment: 4500,
      totalPrice: 15000,
    );

    await _db.collection('bookings').doc(b1.id).set(b1.toMap());
    await _db.collection('bookings').doc(b2.id).set(b2.toMap());
  }
}