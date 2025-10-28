import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:flutter/foundation.dart';

/// Service for managing bookings
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get bookings for a specialist
  Future<List<Booking>> getSpecialistBookings(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map(Booking.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('Error getting specialist bookings: $e');
      return [];
    }
  }

  /// Get bookings for a client
  Future<List<Booking>> getClientBookings(String clientId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('clientId', isEqualTo: clientId)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map(Booking.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('Error getting client bookings: $e');
      return [];
    }
  }

  /// Get bookings by status
  Future<List<Booking>> getBookingsByStatus(BookingStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: status.name)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map(Booking.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('Error getting bookings by status: $e');
      return [];
    }
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting booking by ID: $e');
      return null;
    }
  }

  /// Create a new booking
  Future<String?> createBooking(Booking booking) async {
    try {
      final docRef =
          await _firestore.collection('bookings').add(booking.toFirestore());

      debugPrint('Booking created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return null;
    }
  }

  /// Update booking status
  Future<bool> updateBookingStatus(
      String bookingId, BookingStatus status,) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('Booking status updated to: ${status.name}');
      return true;
    } catch (e) {
      debugPrint('Error updating booking status: $e');
      return false;
    }
  }

  /// Update booking
  Future<bool> updateBooking(Booking booking) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.id)
          .update(booking.toFirestore());

      debugPrint('Booking updated: ${booking.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating booking: $e');
      return false;
    }
  }

  /// Delete booking
  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();

      debugPrint('Booking deleted: $bookingId');
      return true;
    } catch (e) {
      debugPrint('Error deleting booking: $e');
      return false;
    }
  }

  /// Get bookings stream for specialist
  Stream<List<Booking>> getSpecialistBookingsStream(String specialistId) {
    return _firestore
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Booking.fromFirestore).toList(),);
  }

  /// Get bookings stream for client
  Stream<List<Booking>> getClientBookingsStream(String clientId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Booking.fromFirestore).toList(),);
  }

  /// Get bookings stream by status
  Stream<List<Booking>> getBookingsByStatusStream(BookingStatus status) {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: status.name)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Booking.fromFirestore).toList(),);
  }

  /// Get booking statistics
  Future<Map<String, int>> getBookingStats(String specialistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;

        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting booking stats: $e');
      return {};
    }
  }

  /// Check if time slot is available
  Future<bool> isTimeSlotAvailable(
    String specialistId,
    DateTime date,
    String time,
    int duration,
  ) async {
    try {
      final startTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(time.split(':')[0]),
        int.parse(time.split(':')[1]),
      );

      final endTime = startTime.add(Duration(hours: duration));

      final querySnapshot = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where(
        'status',
        whereIn: [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name,
          BookingStatus.inProgress.name,
        ],
      ).get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final bookingTime = data['time'] as String;
        final bookingDuration = data['duration'] as int;

        final bookingStartTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(bookingTime.split(':')[0]),
          int.parse(bookingTime.split(':')[1]),
        );

        final bookingEndTime =
            bookingStartTime.add(Duration(hours: bookingDuration));

        // Check for overlap
        if (startTime.isBefore(bookingEndTime) &&
            endTime.isAfter(bookingStartTime)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking time slot availability: $e');
      return false;
    }
  }

  /// Get available time slots for a date
  Future<List<String>> getAvailableTimeSlots(
      String specialistId, DateTime date,) async {
    try {
      final availableSlots = <String>[];
      final workingHours = <int>[9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

      for (final hour in workingHours) {
        final timeSlot = '${hour.toString().padLeft(2, '0')}:00';

        final isAvailable =
            await isTimeSlotAvailable(specialistId, date, timeSlot, 1);

        if (isAvailable) {
          availableSlots.add(timeSlot);
        }
      }

      return availableSlots;
    } catch (e) {
      debugPrint('Error getting available time slots: $e');
      return [];
    }
  }
}
