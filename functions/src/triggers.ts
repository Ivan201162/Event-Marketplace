import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const db = admin.firestore();
const DEDUP_WINDOW_HOURS = 4;
const RATE_LIMIT_EVENTS_PER_MIN = 3;

/**
 * Дедупликация просмотров профиля (4 часа)
 */
async function checkDeduplication(
  specId: string,
  viewerId: string,
): Promise<boolean> {
  const now = admin.firestore.Timestamp.now();
  const windowStart = new Date(now.toMillis() - DEDUP_WINDOW_HOURS * 60 * 60 * 1000);
  const dayBucket = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const dedupKey = `${specId}_${viewerId}_${dayBucket}`;

  const dedupRef = db.collection('dedup_profile_views').doc(dedupKey);
  const dedupDoc = await dedupRef.get();

  if (dedupDoc.exists) {
    const lastView = dedupDoc.data()?.lastView as admin.firestore.Timestamp;
    if (lastView && lastView.toMillis() > windowStart.getTime()) {
      return false; // Дубликат, игнорируем
    }
  }

  // Сохраняем новую запись с TTL 7 дней
  await dedupRef.set({
    specId,
    viewerId,
    lastView: now,
    expiresAt: admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 7 * 24 * 60 * 60 * 1000,
    ),
  });

  return true; // Не дубликат
}

/**
 * Проверка rate limit (3 события/мин на объект от пользователя)
 */
async function checkRateLimit(
  userId: string,
  specId: string,
  eventType: string,
): Promise<boolean> {
  const now = Date.now();
  const oneMinuteAgo = now - 60 * 1000;
  const rateLimitKey = `${userId}_${specId}_${eventType}`;

  // Используем in-memory cache или Firestore TTL doc
  const rateLimitRef = db.collection('rate_limits').doc(rateLimitKey);
  const rateLimitDoc = await rateLimitRef.get();

  if (rateLimitDoc.exists) {
    const data = rateLimitDoc.data();
    const count = data?.count || 0;
    const lastReset = data?.lastReset?.toMillis() || 0;

    if (lastReset > oneMinuteAgo && count >= RATE_LIMIT_EVENTS_PER_MIN) {
      return false; // Превышен лимит
    }

    if (lastReset <= oneMinuteAgo) {
      // Сброс счётчика
      await rateLimitRef.set({
        count: 1,
        lastReset: admin.firestore.Timestamp.now(),
        expiresAt: admin.firestore.Timestamp.fromMillis(now + 2 * 60 * 1000), // TTL 2 мин
      });
      return true;
    }

    // Инкремент существующего счётчика
    await rateLimitRef.update({
      count: FieldValue.increment(1),
    });
    return true;
  }

  // Создаём новую запись
  await rateLimitRef.set({
    count: 1,
    lastReset: admin.firestore.Timestamp.now(),
    expiresAt: admin.firestore.Timestamp.fromMillis(now + 2 * 60 * 1000),
  });
  return true;
}

/**
 * Триггер: создание события просмотра профиля
 */
export const onProfileViewCreated = functions.firestore
  .document('events_profile_views/{eventId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const specId = data.specId;
    const viewerId = data.viewerId;

    if (!specId || !viewerId) {
      console.error('Missing specId or viewerId in profile view event');
      return;
    }

    // Дедупликация
    const isUnique = await checkDeduplication(specId, viewerId);
    if (!isUnique) {
      console.log(`Duplicate profile view ignored: ${specId} by ${viewerId}`);
      return;
    }

    // Rate limit
    const allowed = await checkRateLimit(viewerId, specId, 'profile_view');
    if (!allowed) {
      console.log(`Rate limit exceeded for profile view: ${viewerId} -> ${specId}`);
      return;
    }

    // Инкремент статистики
    const statsRef = db.collection('specialist_stats').doc(specId);
    await statsRef.set(
      {
        impressions: FieldValue.increment(1),
        lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    console.log(`Profile view logged: ${specId} by ${viewerId}`);
  });

/**
 * Триггер: создание события взаимодействия с постом
 */
export const onPostEngagementCreated = functions.firestore
  .document('events_post_engagement/{eventId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const specId = data.specId;
    const type = data.type; // 'like' | 'comment' | 'share'
    const actorId = data.actorId;

    if (!specId || !type || !actorId) {
      console.error('Missing required fields in post engagement event');
      return;
    }

    // Rate limit
    const allowed = await checkRateLimit(actorId, specId, `post_${type}`);
    if (!allowed) {
      console.log(`Rate limit exceeded for post engagement: ${actorId} -> ${specId}`);
      return;
    }

    const statsRef = db.collection('specialist_stats').doc(specId);
    const updates: Record<string, any> = {
      lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Инкремент соответствующих счётчиков
    switch (type) {
      case 'like':
        updates.likes = FieldValue.increment(1);
        break;
      case 'comment':
        updates.comments = FieldValue.increment(1);
        break;
      case 'share':
        updates.shares = FieldValue.increment(1);
        break;
    }

    await statsRef.set(updates, { merge: true });

    console.log(`Post engagement logged: ${specId} - ${type} by ${actorId}`);
  });

/**
 * Триггер: создание события подписки
 */
export const onFollowCreated = functions.firestore
  .document('events_follow/{eventId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const specId = data.specId;
    const followerId = data.followerId;
    const source = data.source;

    if (!specId || !followerId) {
      console.error('Missing specId or followerId in follow event');
      return;
    }

    // Rate limit
    const allowed = await checkRateLimit(followerId, specId, 'follow');
    if (!allowed) {
      console.log(`Rate limit exceeded for follow: ${followerId} -> ${specId}`);
      return;
    }

    const statsRef = db.collection('specialist_stats').doc(specId);
    await statsRef.set(
      {
        followers: FieldValue.increment(1),
        lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // Если источник - просмотр профиля, инкремент newFollowsFromViews
    if (source === 'profile') {
      await statsRef.set(
        {
          newFollowsFromViews: FieldValue.increment(1),
        },
        { merge: true },
      );
    }

    console.log(`Follow logged: ${specId} by ${followerId} from ${source}`);
  });

/**
 * Триггер: создание события заявки
 */
export const onRequestEventCreated = functions.firestore
  .document('events_requests/{eventId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const specId = data.specId;
    const status = data.status; // 'created' | 'completed'
    const customerId = data.customerId;

    if (!specId || !status) {
      console.error('Missing specId or status in request event');
      return;
    }

    const statsRef = db.collection('specialist_stats').doc(specId);
    const updates: Record<string, any> = {
      lastActivityAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (status === 'created') {
      updates.requestsTotal = FieldValue.increment(1);
    } else if (status === 'completed') {
      updates.requestsCompleted = FieldValue.increment(1);
    }

    await statsRef.set(updates, { merge: true });

    console.log(`Request event logged: ${specId} - ${status}`);
  });

/**
 * Триггер: обновление отзыва
 */
export const onReviewWrite = functions.firestore
  .document('reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const reviewData = change.after.exists ? change.after.data() : null;
    const oldReviewData = change.before.exists ? change.before.data() : null;

    if (!reviewData || !reviewData.specialistId) {
      // Отзыв удалён или нет specialistId - пересчитать только если был старый
      if (oldReviewData && oldReviewData.specialistId) {
        await recalculateReviewStats(oldReviewData.specialistId);
      }
      return;
    }

    const specId = reviewData.specialistId;
    await recalculateReviewStats(specId);
  });

/**
 * Пересчитать статистику отзывов
 */
async function recalculateReviewStats(specId: string) {
  const reviewsSnapshot = await db
    .collection('reviews')
    .where('specialistId', '==', specId)
    .get();

  let totalRating = 0;
  let count = 0;

  reviewsSnapshot.forEach((doc) => {
    const data = doc.data();
    const rating = data.rating;
    if (typeof rating === 'number' && rating > 0) {
      totalRating += rating;
      count++;
    }
  });

  const avgRating = count > 0 ? totalRating / count : 0;

  const statsRef = db.collection('specialist_stats').doc(specId);
  await statsRef.set(
    {
      reviewsAvg: avgRating,
      reviewsCount: count,
    },
    { merge: true },
  );

  console.log(`Review stats recalculated for ${specId}: avg=${avgRating}, count=${count}`);
}

