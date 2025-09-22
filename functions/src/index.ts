import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Инициализация Firebase Admin SDK
admin.initializeApp();

// Получение экземпляра Firestore
const db = admin.firestore();

// Получение экземпляра FCM
const messaging = admin.messaging();

// Получение экземпляра Auth
const auth = admin.auth();

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

/**
 * Cloud Function для обработки VK OAuth и создания custom token
 */
export const vkCustomToken = functions.https.onCall(async (data, context) => {
  try {
    const { code } = data;

    if (!code) {
      throw new functions.https.HttpsError('invalid-argument', 'VK code is required');
    }

    // Обмениваем код на access token
    const tokenResponse = await fetch('https://oauth.vk.com/access_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: functions.config().vk.client_id,
        client_secret: functions.config().vk.client_secret,
        redirect_uri: functions.config().vk.redirect_uri,
        code: code,
      }),
    });

    const tokenData = await tokenResponse.json();

    if (tokenData.error) {
      throw new functions.https.HttpsError('internal', `VK token error: ${tokenData.error_description}`);
    }

    // Получаем данные пользователя из VK
    const userResponse = await fetch(
      `https://api.vk.com/method/users.get?user_ids=${tokenData.user_id}&fields=photo_200,domain&access_token=${tokenData.access_token}&v=5.199`
    );

    const userData = await userResponse.json();

    if (userData.error) {
      throw new functions.https.HttpsError('internal', `VK user data error: ${userData.error.error_msg}`);
    }

    const vkUser = userData.response[0];

    // Создаем или находим пользователя в Firebase
    let firebaseUser;
    try {
      firebaseUser = await auth.getUserByEmail(`${vkUser.id}@vk.com`);
    } catch (error) {
      // Пользователь не существует, создаем нового
      firebaseUser = await auth.createUser({
        uid: `vk_${vkUser.id}`,
        email: `${vkUser.id}@vk.com`,
        displayName: `${vkUser.first_name} ${vkUser.last_name}`,
        photoURL: vkUser.photo_200,
      });
    }

    // Создаем custom token
    const customToken = await auth.createCustomToken(firebaseUser.uid, {
      provider: 'vk',
      vk_id: vkUser.id,
      vk_domain: vkUser.domain,
    });

    // Сохраняем данные пользователя в Firestore
    await db.collection('users').doc(firebaseUser.uid).set({
      email: `${vkUser.id}@vk.com`,
      displayName: `${vkUser.first_name} ${vkUser.last_name}`,
      photoURL: vkUser.photo_200,
      role: 'customer',
      socialProvider: 'vk',
      socialId: vkUser.id.toString(),
      vkDomain: vkUser.domain,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { firebaseCustomToken: customToken };
  } catch (error) {
    console.error('VK Custom Token Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create VK custom token');
  }
});

/**
 * Cloud Function для расчета комиссий
 */
export const calculateCommission = functions.https.onCall(async (data, context) => {
  try {
    const { amount, organizationType = 'individual' } = data;

    if (!amount || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid amount is required');
    }

    // Комиссия платформы (5% для всех)
    const platformCommission = amount * 0.05;

    // НДС (20% для коммерческих организаций)
    let vat = 0;
    if (organizationType === 'commercial') {
      vat = amount * 0.20;
    }

    // Итоговая сумма к выплате специалисту
    const specialistAmount = amount - platformCommission - vat;

    return {
      totalAmount: amount,
      platformCommission,
      vat,
      specialistAmount,
      breakdown: {
        originalAmount: amount,
        platformFee: platformCommission,
        vatFee: vat,
        netAmount: specialistAmount,
      }
    };
  } catch (error) {
    console.error('Commission Calculation Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to calculate commission');
  }
});

/**
 * Cloud Function для обработки платежей
 */
export const processPayment = functions.firestore
  .document('payments/{paymentId}')
  .onCreate(async (snap, context) => {
    const payment = snap.data();
    const paymentId = context.params.paymentId;

    try {
      // Здесь должна быть интеграция с платежной системой
      // Пока просто обновляем статус
      await snap.ref.update({
        status: 'processing',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Симулируем обработку платежа
      setTimeout(async () => {
        try {
          await snap.ref.update({
            status: 'completed',
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Отправляем уведомление о завершении платежа
          const userDoc = await db.collection('users').doc(payment.userId).get();
          const user = userDoc.data();

          if (user && user.fcmToken) {
            await messaging.send({
              token: user.fcmToken,
              notification: {
                title: 'Платеж завершен',
                body: `Ваш платеж на сумму ${payment.amount} ${payment.currency} успешно обработан`,
              },
              data: {
                type: 'payment_completed',
                paymentId: paymentId,
                amount: payment.amount.toString(),
                currency: payment.currency,
              },
            });
          }
        } catch (error) {
          console.error('Payment completion error:', error);
          await snap.ref.update({
            status: 'failed',
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }, 5000); // 5 секунд задержки для симуляции

      console.log(`Payment ${paymentId} processing started`);
    } catch (error) {
      console.error('Payment processing error:', error);
      await snap.ref.update({
        status: 'failed',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * Cloud Function для очистки истекших бронирований
 */
export const cleanupExpiredBookings = functions.pubsub
  .schedule('0 2 * * *') // Каждый день в 2:00
  .timeZone('Europe/Moscow')
  .onRun(async (context) => {
    try {
      const now = admin.firestore.Timestamp.now();

      // Находим истекшие бронирования
      const expiredBookings = await db
        .collection('bookings')
        .where('expiresAt', '<=', now)
        .where('status', '==', 'pending')
        .get();

      const batch = db.batch();

      expiredBookings.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: 'cancelled',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          cancellationReason: 'expired',
        });
      });

      await batch.commit();

      console.log(`Cleaned up ${expiredBookings.size} expired bookings`);
    } catch (error) {
      console.error('Cleanup expired bookings error:', error);
    }
  });

/**
 * Cloud Function для отправки уведомлений о годовщинах
 */
export const sendAnniversaryReminders = functions.pubsub
  .schedule('0 9 * * *') // Каждый день в 9:00
  .timeZone('Europe/Moscow')
  .onRun(async (context) => {
    try {
      const today = new Date();
      const todayString = `${today.getMonth() + 1}-${today.getDate()}`;

      // Находим пользователей с годовщинами сегодня
      const usersSnapshot = await db
        .collection('users')
        .where('anniversaryRemindersEnabled', '==', true)
        .where('weddingDate', '!=', null)
        .get();

      for (const doc of usersSnapshot.docs) {
        const user = doc.data();
        const weddingDate = user.weddingDate.toDate();
        const weddingString = `${weddingDate.getMonth() + 1}-${weddingDate.getDate()}`;

        if (weddingString === todayString && user.fcmToken) {
          const years = today.getFullYear() - weddingDate.getFullYear();

          await messaging.send({
            token: user.fcmToken,
            notification: {
              title: 'Поздравляем с годовщиной!',
              body: `Сегодня ${years} лет вашей свадьбы! 🎉`,
            },
            data: {
              type: 'anniversary_reminder',
              years: years.toString(),
            },
          });
        }
      }

      console.log('Anniversary reminders sent');
    } catch (error) {
      console.error('Anniversary reminders error:', error);
    }
  });

