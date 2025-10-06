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
 * Cloud Function для расчета комиссий и налогов
 */
export const calculateCommission = functions.https.onCall(async (data, context) => {
  try {
    const { amount, organizationType = 'individual', taxType = 'none' } = data;

    if (!amount || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid amount is required');
    }

    // Комиссия платформы (5% для всех)
    const platformCommission = amount * 0.05;

    // Расчет налогов в зависимости от типа
    let taxAmount = 0;
    let taxRate = 0;

    switch (taxType) {
      case 'professionalIncome':
        // Налог на профессиональный доход: 4% с физлиц, 6% с юрлиц
        taxRate = 4; // По умолчанию 4%
        taxAmount = amount * (taxRate / 100);
        break;
      case 'simplifiedTax':
        // УСН 6%
        taxRate = 6;
        taxAmount = amount * (taxRate / 100);
        break;
      case 'vat':
        // НДС 20%
        taxRate = 20;
        taxAmount = amount * (taxRate / 100);
        break;
      default:
        taxAmount = 0;
        taxRate = 0;
    }

    // Итоговая сумма к выплате специалисту
    const specialistAmount = amount - platformCommission - taxAmount;

    return {
      totalAmount: amount,
      platformCommission,
      taxAmount,
      taxRate,
      specialistAmount,
      breakdown: {
        originalAmount: amount,
        platformFee: platformCommission,
        taxFee: taxAmount,
        netAmount: specialistAmount,
      }
    };
  } catch (error) {
    console.error('Commission Calculation Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to calculate commission');
  }
});

/**
 * Cloud Function для создания платежа через ЮKassa
 */
export const createYooKassaPayment = functions.https.onCall(async (data, context) => {
  try {
    const { amount, currency = 'RUB', description, returnUrl, paymentId } = data;

    if (!amount || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid amount is required');
    }

    if (!paymentId) {
      throw new functions.https.HttpsError('invalid-argument', 'Payment ID is required');
    }

    // Получаем конфигурацию ЮKassa
    const shopId = functions.config().yookassa?.shop_id;
    const secretKey = functions.config().yookassa?.secret_key;

    if (!shopId || !secretKey) {
      throw new functions.https.HttpsError('failed-precondition', 'YooKassa configuration not found');
    }

    // Создаем платеж в ЮKassa
    const yooKassaResponse = await fetch('https://api.yookassa.ru/v3/payments', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${Buffer.from(`${shopId}:${secretKey}`).toString('base64')}`,
        'Content-Type': 'application/json',
        'Idempotence-Key': paymentId,
      },
      body: JSON.stringify({
        amount: {
          value: amount.toFixed(2),
          currency: currency,
        },
        confirmation: {
          type: 'redirect',
          return_url: returnUrl || 'https://your-app.com/payment/success',
        },
        description: description || `Платеж #${paymentId}`,
        metadata: {
          paymentId: paymentId,
        },
      }),
    });

    if (!yooKassaResponse.ok) {
      const errorData = await yooKassaResponse.json();
      throw new functions.https.HttpsError('internal', `YooKassa error: ${errorData.description}`);
    }

    const paymentData = await yooKassaResponse.json();

    // Обновляем платеж в Firestore
    await db.collection('payments').doc(paymentId).update({
      yooKassaId: paymentData.id,
      confirmationUrl: paymentData.confirmation?.confirmation_url,
      status: 'pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      paymentId: paymentData.id,
      confirmationUrl: paymentData.confirmation?.confirmation_url,
      status: paymentData.status,
    };
  } catch (error) {
    console.error('YooKassa Payment Creation Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create YooKassa payment');
  }
});

/**
 * Cloud Function для создания платежа через CloudPayments
 */
export const createCloudPaymentsPayment = functions.https.onCall(async (data, context) => {
  try {
    const { amount, currency = 'RUB', description, paymentId } = data;

    if (!amount || amount <= 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid amount is required');
    }

    if (!paymentId) {
      throw new functions.https.HttpsError('invalid-argument', 'Payment ID is required');
    }

    // Получаем конфигурацию CloudPayments
    const publicId = functions.config().cloudpayments?.public_id;
    const apiSecret = functions.config().cloudpayments?.api_secret;

    if (!publicId || !apiSecret) {
      throw new functions.https.HttpsError('failed-precondition', 'CloudPayments configuration not found');
    }

    // Создаем платеж в CloudPayments
    const cloudPaymentsResponse = await fetch('https://api.cloudpayments.ru/payments/cards/charge', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${Buffer.from(`${publicId}:${apiSecret}`).toString('base64')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        Amount: amount,
        Currency: currency,
        InvoiceId: paymentId,
        Description: description || `Платеж #${paymentId}`,
        AccountId: paymentId,
        Email: 'customer@example.com', // Получить из контекста пользователя
      }),
    });

    if (!cloudPaymentsResponse.ok) {
      const errorData = await cloudPaymentsResponse.json();
      throw new functions.https.HttpsError('internal', `CloudPayments error: ${errorData.Message}`);
    }

    const paymentData = await cloudPaymentsResponse.json();

    // Обновляем платеж в Firestore
    await db.collection('payments').doc(paymentId).update({
      cloudPaymentsId: paymentData.Model?.TransactionId,
      status: paymentData.Success ? 'completed' : 'failed',
      transactionId: paymentData.Model?.TransactionId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: paymentData.Success,
      transactionId: paymentData.Model?.TransactionId,
      status: paymentData.Success ? 'completed' : 'failed',
    };
  } catch (error) {
    console.error('CloudPayments Payment Creation Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create CloudPayments payment');
  }
});

/**
 * Cloud Function для обработки webhook от ЮKassa
 */
export const yooKassaWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { type, event } = req.body;

    if (type !== 'notification') {
      res.status(400).send('Invalid notification type');
      return;
    }

    const payment = event.object;
    const paymentId = payment.metadata?.paymentId;

    if (!paymentId) {
      res.status(400).send('Payment ID not found in metadata');
      return;
    }

    // Обновляем статус платежа в Firestore
    const updateData: any = {
      yooKassaStatus: payment.status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (payment.status === 'succeeded') {
      updateData.status = 'completed';
      updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
      updateData.transactionId = payment.id;
    } else if (payment.status === 'canceled') {
      updateData.status = 'cancelled';
      updateData.failedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await db.collection('payments').doc(paymentId).update(updateData);

    // Отправляем уведомление пользователю
    const paymentDoc = await db.collection('payments').doc(paymentId).get();
    const paymentData = paymentDoc.data();

    if (paymentData && paymentData.userId) {
      const userDoc = await db.collection('users').doc(paymentData.userId).get();
      const user = userDoc.data();

      if (user && user.fcmToken) {
        await messaging.send({
          token: user.fcmToken,
          notification: {
            title: payment.status === 'succeeded' ? 'Платеж завершен' : 'Платеж отменен',
            body: `Ваш платеж на сумму ${payment.amount.value} ${payment.amount.currency} ${payment.status === 'succeeded' ? 'успешно обработан' : 'был отменен'}`,
          },
          data: {
            type: 'payment_status_changed',
            paymentId: paymentId,
            status: payment.status,
            amount: payment.amount.value,
            currency: payment.amount.currency,
          },
        });
      }
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('YooKassa Webhook Error:', error);
    res.status(500).send('Internal Server Error');
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
      // Обрабатываем разные типы платежей
      if (payment.type === 'hold') {
        // Для заморозок сразу устанавливаем статус pending
        await snap.ref.update({
          status: 'pending',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Hold payment ${paymentId} created`);
        return;
      }

      // Для обычных платежей запускаем обработку
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

          // Если это предоплата, уведомляем специалиста
          if (payment.type === 'deposit') {
            const specialistDoc = await db.collection('users').doc(payment.specialistId).get();
            const specialist = specialistDoc.data();

            if (specialist && specialist.fcmToken) {
              await messaging.send({
                token: specialist.fcmToken,
                notification: {
                  title: 'Получена предоплата',
                  body: `Предоплата ${payment.amount} ${payment.currency} от клиента получена`,
                },
                data: {
                  type: 'deposit_received',
                  paymentId: paymentId,
                  amount: payment.amount.toString(),
                  currency: payment.currency,
                },
              });
            }
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
 * Cloud Function для обработки возвратов
 */
export const processRefund = functions.https.onCall(async (data, context) => {
  try {
    const { paymentId, reason, amount } = data;

    if (!paymentId || !reason) {
      throw new functions.https.HttpsError('invalid-argument', 'Payment ID and reason are required');
    }

    // Получаем оригинальный платеж
    const paymentDoc = await db.collection('payments').doc(paymentId).get();
    const payment = paymentDoc.data();

    if (!payment) {
      throw new functions.https.HttpsError('not-found', 'Payment not found');
    }

    if (payment.status !== 'completed') {
      throw new functions.https.HttpsError('failed-precondition', 'Can only refund completed payments');
    }

    const refundAmount = amount || payment.amount;

    if (refundAmount > payment.amount) {
      throw new functions.https.HttpsError('invalid-argument', 'Refund amount cannot exceed original payment amount');
    }

    // Создаем возврат
    const refundData = {
      bookingId: payment.bookingId,
      userId: payment.userId,
      specialistId: payment.specialistId,
      type: 'refund',
      amount: refundAmount,
      currency: payment.currency,
      status: 'pending',
      method: payment.method,
      description: `Возврат: ${reason}`,
      paymentProvider: payment.paymentProvider,
      metadata: {
        originalPaymentId: paymentId,
        refundReason: reason,
        originalAmount: payment.amount,
        refundPercentage: ((refundAmount / payment.amount) * 100).toFixed(2),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const refundRef = await db.collection('payments').add(refundData);

    // Обновляем статус оригинального платежа
    await db.collection('payments').doc(paymentId).update({
      status: 'refunded',
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundReason: reason,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Отправляем уведомления
    const userDoc = await db.collection('users').doc(payment.userId).get();
    const user = userDoc.data();

    if (user && user.fcmToken) {
      await messaging.send({
        token: user.fcmToken,
        notification: {
          title: 'Возврат создан',
          body: `Возврат на сумму ${refundAmount} ${payment.currency} создан. Причина: ${reason}`,
        },
        data: {
          type: 'refund_created',
          refundId: refundRef.id,
          amount: refundAmount.toString(),
          currency: payment.currency,
        },
      });
    }

    return {
      refundId: refundRef.id,
      amount: refundAmount,
      currency: payment.currency,
      status: 'pending',
    };
  } catch (error) {
    console.error('Refund processing error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to process refund');
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

/**
 * Cloud Function для расчета средних цен специалистов
 */
export const calculateAveragePrices = functions.pubsub
  .schedule('0 2 * * *') // Каждый день в 2:00
  .timeZone('Europe/Moscow')
  .onRun(async (context) => {
    try {
      console.log('Starting average prices calculation...');

      // Получаем всех специалистов
      const specialistsSnapshot = await db.collection('specialists').get();

      const batch = db.batch();
      let updatedCount = 0;

      for (const specialistDoc of specialistsSnapshot.docs) {
        const specialistId = specialistDoc.id;

        // Получаем завершенные бронирования специалиста
        const bookingsSnapshot = await db
          .collection('bookings')
          .where('specialistId', '==', specialistId)
          .where('status', '==', 'completed')
          .get();

        if (bookingsSnapshot.docs.length === 0) continue;

        // Группируем по категориям услуг
        const pricesByCategory: { [key: string]: number[] } = {};

        for (const bookingDoc of bookingsSnapshot.docs) {
          const booking = bookingDoc.data();
          const category = booking.eventType || 'other';

          if (!pricesByCategory[category]) {
            pricesByCategory[category] = [];
          }
          pricesByCategory[category].push(booking.totalPrice);
        }

        // Рассчитываем средние цены
        const averagePrices: { [key: string]: number } = {};
        Object.keys(pricesByCategory).forEach(category => {
          const prices = pricesByCategory[category];
          if (prices.length > 0) {
            const sum = prices.reduce((a, b) => a + b, 0);
            averagePrices[category] = sum / prices.length;
          }
        });

        if (Object.keys(averagePrices).length > 0) {
          batch.update(specialistDoc.ref, {
            'avgPriceByService': averagePrices,
            'lastPriceUpdateAt': admin.firestore.FieldValue.serverTimestamp(),
            'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
          });
          updatedCount++;
        }
      }

      await batch.commit();
      console.log(`Average prices calculated for ${updatedCount} specialists`);
    } catch (error) {
      console.error('Average prices calculation error:', error);
    }
  });

/**
 * Cloud Function для обновления средних цен при завершении бронирования
 */
export const updateSpecialistAveragePrice = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    // Проверяем, изменился ли статус на completed
    if (before.status !== 'completed' && after.status === 'completed') {
      try {
        const specialistId = after.specialistId;
        if (!specialistId) return;

        console.log(`Updating average price for specialist ${specialistId} after booking ${bookingId} completion`);

        // Получаем все завершенные бронирования специалиста
        const bookingsSnapshot = await db
          .collection('bookings')
          .where('specialistId', '==', specialistId)
          .where('status', '==', 'completed')
          .get();

        if (bookingsSnapshot.docs.length === 0) return;

        // Группируем по категориям услуг
        const pricesByCategory: { [key: string]: number[] } = {};

        for (const bookingDoc of bookingsSnapshot.docs) {
          const booking = bookingDoc.data();
          const category = booking.eventType || 'other';

          if (!pricesByCategory[category]) {
            pricesByCategory[category] = [];
          }
          pricesByCategory[category].push(booking.totalPrice);
        }

        // Рассчитываем средние цены
        const averagePrices: { [key: string]: number } = {};
        Object.keys(pricesByCategory).forEach(category => {
          const prices = pricesByCategory[category];
          if (prices.length > 0) {
            const sum = prices.reduce((a, b) => a + b, 0);
            averagePrices[category] = sum / prices.length;
          }
        });

        // Обновляем специалиста
        await db.collection('specialists').doc(specialistId).update({
          'avgPriceByService': averagePrices,
          'lastPriceUpdateAt': admin.firestore.FieldValue.serverTimestamp(),
          'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Average prices updated for specialist ${specialistId}`);
      } catch (error) {
        console.error('Error updating specialist average price:', error);
      }
    }
  });

/**
 * Cloud Function для пересчёта рейтинга специалиста при создании отзыва
 */
export const onReviewCreated = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap, context) => {
    const review = snap.data();
    const reviewId = context.params.reviewId;

    try {
      const specialistId = review.specialistId;
      if (!specialistId) {
        console.error('Specialist ID not found in review');
        return;
      }

      console.log(`Recalculating rating for specialist ${specialistId} after review ${reviewId} creation`);

      // Получаем все отзывы специалиста (исключая жалобы)
      const reviewsSnapshot = await db
        .collection('reviews')
        .where('specialistId', '==', specialistId)
        .where('reported', '==', false)
        .get();

      if (reviewsSnapshot.docs.length === 0) {
        console.log('No reviews found for specialist');
        return;
      }

      // Рассчитываем средний рейтинг
      let totalRating = 0;
      let reviewsCount = 0;

      for (const reviewDoc of reviewsSnapshot.docs) {
        const reviewData = reviewDoc.data();
        totalRating += reviewData.rating;
        reviewsCount++;
      }

      const avgRating = totalRating / reviewsCount;

      // Обновляем специалиста
      await db.collection('specialists').doc(specialistId).update({
        avgRating: Math.round(avgRating * 10) / 10, // Округляем до 1 знака после запятой
        reviewsCount: reviewsCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Rating updated for specialist ${specialistId}: ${avgRating.toFixed(1)} (${reviewsCount} reviews)`);

      // Отправляем уведомление специалисту о новом отзыве
      const specialistDoc = await db.collection('specialists').doc(specialistId).get();
      const specialist = specialistDoc.data();

      if (specialist && specialist.fcmToken) {
        await messaging.send({
          token: specialist.fcmToken,
          notification: {
            title: 'Новый отзыв',
            body: `Получен новый отзыв с оценкой ${review.rating} звезд`,
          },
          data: {
            type: 'new_review',
            reviewId: reviewId,
            rating: review.rating.toString(),
            avgRating: avgRating.toFixed(1),
            reviewsCount: reviewsCount.toString(),
          },
        });
      }
    } catch (error) {
      console.error('Error recalculating specialist rating:', error);
    }
  });

/**
 * Cloud Function для пересчёта рейтинга специалиста при обновлении отзыва
 */
export const onReviewUpdated = functions.firestore
  .document('reviews/{reviewId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const reviewId = context.params.reviewId;

    // Проверяем, изменился ли рейтинг
    if (before.rating === after.rating && before.reported === after.reported) {
      return;
    }

    try {
      const specialistId = after.specialistId;
      if (!specialistId) {
        console.error('Specialist ID not found in review');
        return;
      }

      console.log(`Recalculating rating for specialist ${specialistId} after review ${reviewId} update`);

      // Получаем все отзывы специалиста (исключая жалобы)
      const reviewsSnapshot = await db
        .collection('reviews')
        .where('specialistId', '==', specialistId)
        .where('reported', '==', false)
        .get();

      if (reviewsSnapshot.docs.length === 0) {
        // Если нет отзывов, устанавливаем рейтинг в 0
        await db.collection('specialists').doc(specialistId).update({
          avgRating: 0.0,
          reviewsCount: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // Рассчитываем средний рейтинг
      let totalRating = 0;
      let reviewsCount = 0;

      for (const reviewDoc of reviewsSnapshot.docs) {
        const reviewData = reviewDoc.data();
        totalRating += reviewData.rating;
        reviewsCount++;
      }

      const avgRating = totalRating / reviewsCount;

      // Обновляем специалиста
      await db.collection('specialists').doc(specialistId).update({
        avgRating: Math.round(avgRating * 10) / 10, // Округляем до 1 знака после запятой
        reviewsCount: reviewsCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Rating updated for specialist ${specialistId}: ${avgRating.toFixed(1)} (${reviewsCount} reviews)`);
    } catch (error) {
      console.error('Error recalculating specialist rating after update:', error);
    }
  });

/**
 * Cloud Function для пересчёта рейтинга специалиста при удалении отзыва
 */
export const onReviewDeleted = functions.firestore
  .document('reviews/{reviewId}')
  .onDelete(async (snap, context) => {
    const review = snap.data();
    const reviewId = context.params.reviewId;

    try {
      const specialistId = review.specialistId;
      if (!specialistId) {
        console.error('Specialist ID not found in deleted review');
        return;
      }

      console.log(`Recalculating rating for specialist ${specialistId} after review ${reviewId} deletion`);

      // Получаем все оставшиеся отзывы специалиста (исключая жалобы)
      const reviewsSnapshot = await db
        .collection('reviews')
        .where('specialistId', '==', specialistId)
        .where('reported', '==', false)
        .get();

      if (reviewsSnapshot.docs.length === 0) {
        // Если нет отзывов, устанавливаем рейтинг в 0
        await db.collection('specialists').doc(specialistId).update({
          avgRating: 0.0,
          reviewsCount: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // Рассчитываем средний рейтинг
      let totalRating = 0;
      let reviewsCount = 0;

      for (const reviewDoc of reviewsSnapshot.docs) {
        const reviewData = reviewDoc.data();
        totalRating += reviewData.rating;
        reviewsCount++;
      }

      const avgRating = totalRating / reviewsCount;

      // Обновляем специалиста
      await db.collection('specialists').doc(specialistId).update({
        avgRating: Math.round(avgRating * 10) / 10, // Округляем до 1 знака после запятой
        reviewsCount: reviewsCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Rating updated for specialist ${specialistId}: ${avgRating.toFixed(1)} (${reviewsCount} reviews)`);
    } catch (error) {
      console.error('Error recalculating specialist rating after deletion:', error);
    }
  });

/**
 * Cloud Function для отправки напоминания об отзыве после завершения заказа
 */
export const sendReviewReminder = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    // Проверяем, изменился ли статус на completed
    if (before.status !== 'completed' && after.status === 'completed') {
      try {
        const customerId = after.customerId;
        const specialistId = after.specialistId;

        if (!customerId || !specialistId) {
          console.error('Customer ID or Specialist ID not found in booking');
          return;
        }

        // Проверяем, есть ли уже отзыв для этого заказа
        const existingReview = await db
          .collection('reviews')
          .where('bookingId', '==', bookingId)
          .limit(1)
          .get();

        if (!existingReview.empty) {
          console.log('Review already exists for booking', bookingId);
          return;
        }

        // Получаем данные клиента
        const customerDoc = await db.collection('users').doc(customerId).get();
        const customer = customerDoc.data();

        // Получаем данные специалиста
        const specialistDoc = await db.collection('specialists').doc(specialistId).get();
        const specialist = specialistDoc.data();

        if (!customer || !specialist) {
          console.error('Customer or specialist not found');
          return;
        }

        // Отправляем напоминание об отзыве через 24 часа
        setTimeout(async () => {
          try {
            if (customer.fcmToken) {
              await messaging.send({
                token: customer.fcmToken,
                notification: {
                  title: 'Оцените специалиста',
                  body: `Пожалуйста, оставьте отзыв о работе ${specialist.name}`,
                },
                data: {
                  type: 'review_reminder',
                  bookingId: bookingId,
                  specialistId: specialistId,
                  specialistName: specialist.name,
                },
              });
            }
          } catch (error) {
            console.error('Error sending review reminder:', error);
          }
        }, 24 * 60 * 60 * 1000); // 24 часа

        console.log(`Review reminder scheduled for booking ${bookingId}`);
      } catch (error) {
        console.error('Error scheduling review reminder:', error);
      }
    }
  });

