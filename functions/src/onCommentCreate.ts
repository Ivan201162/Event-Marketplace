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
      `PUSH_SENT to ${userId}: ${response.successCount} successful, ${response.failureCount} failed`,
    );
  } catch (error) {
    functions.logger.error(`Error sending push to ${userId}:`, error);
  }
}

/**
 * Триггер: создание нового комментария
 * Структура: comments/{contentId}/comments/{commentId}
 */
export const onCommentCreate = functions.firestore
  .document('comments/{contentId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const commentData = snap.data();
    const authorId = commentData.authorId as string;
    const contentType = commentData.contentType as string; // 'posts', 'reels', 'stories', 'ideas'
    const contentId = context.params.contentId;
    const commentId = context.params.commentId;
    const commentText = (commentData.text as string) || '';

    if (!authorId || !contentType || !contentId) {
      functions.logger.error('Missing required fields in comment');
      return;
    }

    try {
      // Получаем данные автора комментария
      const authorDoc = await db.collection('users').doc(authorId).get();
      const authorData = authorDoc.data();
      const authorName =
        `${authorData?.firstName ?? ''} ${authorData?.lastName ?? ''}`.trim() ||
        'Пользователь';

      // Получаем данные контента
      const contentDoc = await db.collection(contentType).doc(contentId).get();
      if (!contentDoc.exists) {
        functions.logger.warn(`Content ${contentId} not found in ${contentType}`);
        return;
      }

      const contentData = contentDoc.data();
      const contentAuthorId = contentData?.authorId as string | undefined;

      // Не отправляем уведомление, если автор комментария = автор контента
      if (!contentAuthorId || contentAuthorId === authorId) {
        functions.logger.info(
          `Skipping notification: comment author is content author`,
        );
        return;
      }

      // Получаем данные автора контента
      const contentAuthorDoc = await db.collection('users').doc(contentAuthorId).get();
      const contentAuthorData = contentAuthorDoc.data();
      const contentTitle =
        contentData?.title ||
        contentData?.description?.substring(0, 50) ||
        'ваш контент';

      // Отправляем уведомление автору контента
      await sendPushNotification(
        contentAuthorId,
        'Новый комментарий',
        `${authorName} прокомментировал(а) "${contentTitle}"`,
        {
          type: 'comment',
          contentType,
          contentId,
          commentId,
          authorId,
        },
      );

      // Создаём запись в notifications
      await db.collection('notifications').add({
        userId: contentAuthorId,
        type: 'comment',
        title: 'Новый комментарий',
        body: `${authorName} прокомментировал(a) "${contentTitle}"`,
        data: {
          contentType,
          contentId,
          commentId,
          authorId,
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      functions.logger.info(
        `FCM_RECEIVED: Comment ${commentId} notification sent to ${contentAuthorId}`,
      );
    } catch (error) {
      functions.logger.error(`Error processing comment ${commentId}:`, error);
    }
  });

