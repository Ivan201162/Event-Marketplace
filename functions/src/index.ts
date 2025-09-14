import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Инициализация Firebase Admin SDK
admin.initializeApp();

// Получение экземпляра Firestore
const db = admin.firestore();

// Получение экземпляра FCM
const messaging = admin.messaging();

/**
 * Cloud Function для отправки уведомлений при создании бронирования
 */
export const onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const bookingId = context.params.bookingId;

    try {
      // Получаем данные специалиста
      const specialistDoc = await db.collection('specialists').doc(booking.specialistId).get();
      const specialist = specialistDoc.data();

      // Получаем данные клиента
      const customerDoc = await db.collection('users').doc(booking.customerId).get();
      const customer = customerDoc.data();

      if (!specialist || !customer) {
        console.error('Specialist or customer not found');
        return;
      }

      // Отправляем уведомление специалисту
      if (specialist.fcmToken) {
        await messaging.send({
          token: specialist.fcmToken,
          notification: {
            title: 'Новое бронирование',
            body: `${customer.name || 'Клиент'} забронировал ваши услуги на ${formatDate(booking.eventDate)}`,
          },
          data: {
            type: 'booking_created',
            bookingId: bookingId,
            customerId: booking.customerId,
            specialistId: booking.specialistId,
          },
        });
      }

      // Отправляем уведомление клиенту
      if (customer.fcmToken) {
        await messaging.send({
          token: customer.fcmToken,
          notification: {
            title: 'Бронирование создано',
            body: `Ваше бронирование у ${specialist.name} на ${formatDate(booking.eventDate)} создано`,
          },
          data: {
            type: 'booking_created',
            bookingId: bookingId,
            customerId: booking.customerId,
            specialistId: booking.specialistId,
          },
        });
      }

      console.log(`Notifications sent for booking ${bookingId}`);
    } catch (error) {
      console.error('Error sending notifications:', error);
    }
  });

/**
 * Cloud Function для отправки уведомлений при изменении статуса бронирования
 */
export const onBookingStatusChanged = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    // Проверяем, изменился ли статус
    if (before.status === after.status) {
      return;
    }

    try {
      // Получаем данные специалиста
      const specialistDoc = await db.collection('specialists').doc(after.specialistId).get();
      const specialist = specialistDoc.data();

      // Получаем данные клиента
      const customerDoc = await db.collection('users').doc(after.customerId).get();
      const customer = customerDoc.data();

      if (!specialist || !customer) {
        console.error('Specialist or customer not found');
        return;
      }

      let title = '';
      let body = '';
      let notificationType = '';

      switch (after.status) {
        case 'confirmed':
          title = 'Бронирование подтверждено';
          body = `${specialist.name} подтвердил ваше бронирование на ${formatDate(after.eventDate)}`;
          notificationType = 'booking_confirmed';
          break;
        case 'rejected':
          title = 'Бронирование отклонено';
          body = `${specialist.name} отклонил ваше бронирование на ${formatDate(after.eventDate)}`;
          notificationType = 'booking_rejected';
          break;
        case 'cancelled':
          title = 'Бронирование отменено';
          body = `Бронирование на ${formatDate(after.eventDate)} было отменено`;
          notificationType = 'booking_cancelled';
          break;
        default:
          return;
      }

      // Отправляем уведомление клиенту
      if (customer.fcmToken) {
        await messaging.send({
          token: customer.fcmToken,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: notificationType,
            bookingId: bookingId,
            customerId: after.customerId,
            specialistId: after.specialistId,
          },
        });
      }

      // Если статус изменил клиент, уведомляем специалиста
      if (after.status === 'cancelled' && before.status !== 'cancelled') {
        if (specialist.fcmToken) {
          await messaging.send({
            token: specialist.fcmToken,
            notification: {
              title: 'Бронирование отменено',
              body: `${customer.name || 'Клиент'} отменил бронирование на ${formatDate(after.eventDate)}`,
            },
            data: {
              type: 'booking_cancelled',
              bookingId: bookingId,
              customerId: after.customerId,
              specialistId: after.specialistId,
            },
          });
        }
      }

      console.log(`Status change notification sent for booking ${bookingId}`);
    } catch (error) {
      console.error('Error sending status change notification:', error);
    }
  });

/**
 * Cloud Function для отправки напоминаний о предстоящих бронированиях
 */
export const sendBookingReminders = functions.pubsub
  .schedule('0 9 * * *') // Каждый день в 9:00
  .timeZone('Europe/Moscow')
  .onRun(async (context) => {
    try {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      tomorrow.setHours(0, 0, 0, 0);

      const dayAfterTomorrow = new Date(tomorrow);
      dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);

      // Получаем бронирования на завтра
      const bookingsSnapshot = await db
        .collection('bookings')
        .where('eventDate', '>=', admin.firestore.Timestamp.fromDate(tomorrow))
        .where('eventDate', '<', admin.firestore.Timestamp.fromDate(dayAfterTomorrow))
        .where('status', '==', 'confirmed')
        .get();

      for (const doc of bookingsSnapshot.docs) {
        const booking = doc.data();
        
        // Получаем данные клиента
        const customerDoc = await db.collection('users').doc(booking.customerId).get();
        const customer = customerDoc.data();

        // Получаем данные специалиста
        const specialistDoc = await db.collection('specialists').doc(booking.specialistId).get();
        const specialist = specialistDoc.data();

        if (!customer || !specialist) continue;

        // Отправляем напоминание клиенту
        if (customer.fcmToken) {
          await messaging.send({
            token: customer.fcmToken,
            notification: {
              title: 'Напоминание о бронировании',
              body: `Завтра у вас бронирование у ${specialist.name} в ${formatTime(booking.eventDate)}`,
            },
            data: {
              type: 'booking_reminder',
              bookingId: doc.id,
              customerId: booking.customerId,
              specialistId: booking.specialistId,
            },
          });
        }

        // Отправляем напоминание специалисту
        if (specialist.fcmToken) {
          await messaging.send({
            token: specialist.fcmToken,
            notification: {
              title: 'Напоминание о бронировании',
              body: `Завтра у вас бронирование с ${customer.name || 'клиентом'} в ${formatTime(booking.eventDate)}`,
            },
            data: {
              type: 'booking_reminder',
              bookingId: doc.id,
              customerId: booking.customerId,
              specialistId: booking.specialistId,
            },
          });
        }
      }

      console.log(`Reminders sent for ${bookingsSnapshot.size} bookings`);
    } catch (error) {
      console.error('Error sending reminders:', error);
    }
  });

/**
 * Вспомогательная функция для форматирования даты
 */
function formatDate(timestamp: any): string {
  const date = timestamp.toDate();
  return date.toLocaleDateString('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

/**
 * Вспомогательная функция для форматирования времени
 */
function formatTime(timestamp: any): string {
  const date = timestamp.toDate();
  return date.toLocaleTimeString('ru-RU', {
    hour: '2-digit',
    minute: '2-digit',
  });
}

