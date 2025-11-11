import * as admin from 'firebase-admin';

admin.initializeApp();

// Экспорт триггеров
export {
  onProfileViewCreated,
  onPostEngagementCreated,
  onFollowCreated,
  onRequestEventCreated,
  onReviewWrite,
} from './triggers';

// Экспорт cron функции
export { recomputeScores } from './computeScores';

// Экспорт wipe функции
export { wipeTestUser } from './wipeTestUser';

// Экспорт cleanup stories
export { cleanupExpiredStories } from './cleanupStories';

// Экспорт push notifications
export { sendPushOnBooking, sendPushOnMessage } from './pushNotifications';

// Экспорт comment notifications
export { onCommentCreate } from './onCommentCreate';