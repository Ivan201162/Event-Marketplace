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
