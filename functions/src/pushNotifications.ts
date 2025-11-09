import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Отправка push-уведомления пользователю
 */
async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      functions.logger.warn(`User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmTokens = userData?.fcmTokens as string[] | undefined;

    if (!fcmTokens || fcmTokens.length === 0) {
      functions.logger.warn(`No FCM tokens for user ${userId}`);
      return;
    }

    const message: admin.messaging.MulticastMessage = {
      notification: {
        title,
        body,
      },
      data: data || {},
      tokens: fcmTokens,
    };

    const response = await messaging.sendEachForMulticast(message);
    functions.logger.info(
      `Sent push to ${userId}: ${response.successCount} successful, ${response.failureCount} failed`,
    );
  } catch (error) {
    functions.logger.error(`Error sending push to ${userId}:`, error);
  }
}

/**
 * Триггер: создание нового бронирования
 */
export const sendPushOnBooking = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const bookingData = snap.data();
    const specialistId = bookingData.specialistId as string;
    const clientId = bookingData.clientId as string;
    const bookingId = context.params.bookingId;

    if (!specialistId) {
      functions.logger.error('Missing specialistId in booking');
      return;
    }

    // Получаем данные специалиста
    const specialistDoc = await db.collection('users').doc(specialistId).get();
    const specialistData = specialistDoc.data();
    const specialistName =
      `${specialistData?.firstName ?? ''} ${specialistData?.lastName ?? ''}`.trim() ||
      'Специалист';

    // Отправляем уведомление специалисту
    await sendPushNotification(
      specialistId,
      'Новое бронирование',
      `У вас новое бронирование от клиента`,
      {
        type: 'booking',
        bookingId,
        clientId,
      },
    );

    functions.logger.info(`Push sent for booking ${bookingId} to specialist ${specialistId}`);
  });

/**
 * Триггер: создание нового сообщения в чате
 */
export const sendPushOnMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const senderId = messageData.senderId as string;
    const chatId = context.params.chatId;
    const messageText = (messageData.text as string) || '';

    if (!senderId || !chatId) {
      functions.logger.error('Missing senderId or chatId in message');
      return;
    }

    // Получаем данные чата
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      functions.logger.error(`Chat ${chatId} not found`);
      return;
    }

    const chatData = chatDoc.data();
    const participants = (chatData?.participants as string[]) || [];

    // Получаем данные отправителя
    const senderDoc = await db.collection('users').doc(senderId).get();
    const senderData = senderDoc.data();
    const senderName =
      `${senderData?.firstName ?? ''} ${senderData?.lastName ?? ''}`.trim() ||
      'Пользователь';

    // Отправляем уведомление всем участникам кроме отправителя
    for (const participantId of participants) {
      if (participantId !== senderId) {
        await sendPushNotification(
          participantId,
          senderName,
          messageText.length > 100 ? `${messageText.substring(0, 100)}...` : messageText,
          {
            type: 'message',
            chatId,
            senderId,
          },
        );
      }
    }

    functions.logger.info(`Push sent for message in chat ${chatId}`);
  });

