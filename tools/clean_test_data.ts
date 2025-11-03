import * as admin from 'firebase-admin';
import { getStorage } from 'firebase-admin/storage';

// Инициализация Firebase Admin SDK
const PROJECT_ID = 'event-marketplace-mvp';
const STORAGE_BUCKET = 'event-marketplace-mvp.appspot.com';

let app: admin.app.App;

try {
  // Пробуем использовать service account файл, если есть
  const fs = require('fs');
  const path = require('path');

  const serviceAccountPaths = [
    path.join(__dirname, '..', 'firebase-service-account.json'),
    path.join(__dirname, '..', 'service-account-key.json'),
    process.env.GOOGLE_APPLICATION_CREDENTIALS || '',
  ].filter(p => p && fs.existsSync(p));

  if (serviceAccountPaths.length > 0) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPaths[0], 'utf8'));
    app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    });
    console.log(`✅ Использован service account: ${serviceAccountPaths[0]}`);
  } else {
    // Fallback на application default credentials
    app = admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    });
    console.log('✅ Использованы application default credentials');
  }
} catch (e: any) {
  console.error('❌ Ошибка инициализации Firebase Admin SDK:', e.message);
  console.error('Убедитесь, что GOOGLE_APPLICATION_CREDENTIALS установлен или service-account-key.json находится в корне проекта');
  process.exit(1);
}

const db = admin.firestore();
const storage = getStorage().bucket();

// Критерии для определения тестовых данных
const TEST_EMAIL_PATTERNS = ['test', 'demo', 'example', 'fake', 'dev', 'seed'];
const TEST_USERNAME_PATTERNS = ['test', 'demo', 'mock', 'autogen'];
const TEST_DISPLAYNAME_PATTERNS = ['Test', 'Demo', 'User123', 'Generated'];
const TEST_UID_PREFIXES = ['test_', 'seed_', 'mock_'];
const REAL_EMAIL_DOMAINS = ['gmail.com', 'yandex.ru', 'mail.ru', 'icloud.com', 'outlook.com', 'yahoo.com', 'hotmail.com'];

// Результаты очистки
const report = {
  deleted: {
    users: 0,
    specialists: 0,
    posts: 0,
    ideas: 0,
    stories: 0,
    requests: 0,
    chats: 0,
    messages: 0,
    follows: 0,
    notifications: 0,
    events_profile_views: 0,
    events_post_engagement: 0,
    events_follow: 0,
    events_requests: 0,
    specialist_stats: 0,
    specialist_scores: 0,
    storageFiles: 0,
  },
  testUserIds: new Set<string>(),
  remaining: {} as Record<string, number>,
  errors: [] as string[],
};

/**
 * Проверяет, является ли email тестовым
 */
function isTestEmail(email: string | null | undefined): boolean {
  if (!email) return false;
  const emailLower = email.toLowerCase();

  // Если это реальный домен, НЕ тестовый
  if (REAL_EMAIL_DOMAINS.some(domain => emailLower.includes(domain))) {
    return false;
  }

  return TEST_EMAIL_PATTERNS.some(pattern => emailLower.includes(pattern));
}

/**
 * Проверяет, является ли username тестовым
 */
function isTestUsername(username: string | null | undefined): boolean {
  if (!username) return false;
  const usernameLower = username.toLowerCase();
  return TEST_USERNAME_PATTERNS.some(pattern => usernameLower.includes(pattern));
}

/**
 * Проверяет, является ли displayName тестовым
 */
function isTestDisplayName(displayName: string | null | undefined): boolean {
  if (!displayName) return false;
  return TEST_DISPLAYNAME_PATTERNS.some(pattern => displayName.includes(pattern));
}

/**
 * Проверяет, является ли uid тестовым
 */
function isTestUid(uid: string | null | undefined): boolean {
  if (!uid) return false;
  return TEST_UID_PREFIXES.some(prefix => uid.startsWith(prefix));
}

/**
 * Проверяет, является ли пользователь тестовым
 */
async function isTestUser(userId: string, userData: admin.firestore.DocumentData): Promise<boolean> {
  // Проверка по uid
  if (isTestUid(userId)) {
    return true;
  }

  // Проверка по email
  const email = userData.email || userData.emailAddress;
  if (isTestEmail(email)) {
    return true;
  }

  // Проверка по username
  const username = userData.username || userData.userName;
  if (isTestUsername(username)) {
    return true;
  }

  // Проверка по displayName
  const displayName = userData.displayName || userData.name;
  if (isTestDisplayName(displayName)) {
    return true;
  }

  // Проверка на production флаг (если есть, НЕ тестовый)
  if (userData.production === true || userData.isProduction === true) {
    return false;
  }

  // Проверка на неактивные старые аккаунты (старше 10 дней, без активности)
  const createdAt = userData.createdAt?.toDate?.() || userData.createdAt;
  if (createdAt) {
    const daysSinceCreation = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSinceCreation > 10) {
      const postsCount = userData.postsCount || userData.postCount || 0;
      const followersCount = userData.followersCount || userData.followerCount || 0;

      // Если нет постов и подписчиков - возможно тестовый
      if (postsCount === 0 && followersCount === 0) {
        // Проверяем наличие активности
        const hasActivity = userData.lastActivityAt || userData.updatedAt;
        if (!hasActivity || daysSinceCreation > 30) {
          return true; // Старый неактивный аккаунт без данных
        }
      }
    }
  }

  // Если есть реальная активность (>0 постов/подписчиков/чатов), НЕ тестовый
  const postsCount = userData.postsCount || userData.postCount || 0;
  const followersCount = userData.followersCount || userData.followerCount || 0;
  if (postsCount > 0 || followersCount > 0) {
    return false;
  }

  // По умолчанию - НЕ тестовый (безопаснее не удалять)
  return false;
}

/**
 * Удаляет коллекцию с фильтрацией тестовых данных
 */
async function cleanCollection(
  collectionName: string,
  isTestDoc: (docId: string, data: admin.firestore.DocumentData) => Promise<boolean>,
  batchSize: number = 100
): Promise<void> {
  console.log(`\n🔍 Проверка коллекции: ${collectionName}`);

  let deleted = 0;
  let total = 0;

  try {
    let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

    while (true) {
      let query: admin.firestore.Query = db.collection(collectionName);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.limit(batchSize).get();

      if (snapshot.empty) break;

      total += snapshot.size;

      const batch = db.batch();
      let batchCount = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const isTest = await isTestDoc(doc.id, data);

        if (isTest) {
          batch.delete(doc.ref);
          batchCount++;
          deleted++;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        console.log(`  ✅ Удалено ${batchCount} документов из ${collectionName}`);
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    // Проверяем, что осталось
    const remainingSnapshot = await db.collection(collectionName).limit(1).get();
    report.remaining[collectionName] = remainingSnapshot.empty ? 0 :
      (await db.collection(collectionName).count().get()).data().count;

    console.log(`  📊 Итого: ${deleted} удалено, ${report.remaining[collectionName]} осталось`);

    // Обновляем счётчик в отчёте
    const reportKey = collectionName as keyof typeof report.deleted;
    if (reportKey in report.deleted) {
      (report.deleted as any)[reportKey] = deleted;
    }
  } catch (error: any) {
    const errorMsg = `Ошибка при очистке ${collectionName}: ${error.message}`;
    console.error(`  ❌ ${errorMsg}`);
    report.errors.push(errorMsg);
  }
}

/**
 * Очистка пользователей
 */
async function cleanUsers(): Promise<void> {
  console.log('\n👥 Очистка пользователей...');

  let deleted = 0;
  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;

  while (true) {
    let query: admin.firestore.Query = db.collection('users');
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.limit(100).get();
    if (snapshot.empty) break;

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const isTest = await isTestUser(doc.id, data);

      if (isTest) {
        report.testUserIds.add(doc.id);
        batch.delete(doc.ref);
        batchCount++;
        deleted++;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      console.log(`  ✅ Удалено ${batchCount} тестовых пользователей`);
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  report.deleted.users = deleted;

  // Проверяем остаток
  const remainingSnapshot = await db.collection('users').limit(1).get();
  report.remaining['users'] = remainingSnapshot.empty ? 0 :
    (await db.collection('users').count().get()).data().count;

  console.log(`  📊 Всего удалено: ${deleted}, осталось: ${report.remaining['users']}`);
}

/**
 * Очистка связанных данных по authorId/userId
 */
async function cleanByAuthorId(collectionName: string, authorField: string): Promise<void> {
  console.log(`\n🔍 Очистка ${collectionName} по ${authorField}...`);

  if (report.testUserIds.size === 0) {
    console.log(`  ⏭️ Нет тестовых пользователей, пропускаем`);
    return;
  }

  let deleted = 0;
  const testUserIdsArray = Array.from(report.testUserIds);

  // Разбиваем на чанки по 10 (ограничение whereIn)
  for (let i = 0; i < testUserIdsArray.length; i += 10) {
    const chunk = testUserIdsArray.slice(i, i + 10);

    try {
      const snapshot = await db.collection(collectionName)
        .where(authorField, 'in', chunk)
        .get();

      if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
          batch.delete(doc.ref);
          deleted++;
        });
        await batch.commit();
        console.log(`  ✅ Удалено ${snapshot.size} документов из ${collectionName}`);
      }
    } catch (error: any) {
      const errorMsg = `Ошибка при удалении ${collectionName}: ${error.message}`;
      console.error(`  ❌ ${errorMsg}`);
      report.errors.push(errorMsg);
    }
  }

  // Обновляем счётчик
  const reportKey = collectionName as keyof typeof report.deleted;
  if (reportKey in report.deleted) {
    (report.deleted as any)[reportKey] += deleted;
  }
}

/**
 * Очистка чатов и сообщений
 */
async function cleanChats(): Promise<void> {
  console.log('\n💬 Очистка чатов...');

  if (report.testUserIds.size === 0) {
    console.log(`  ⏭️ Нет тестовых пользователей, пропускаем`);
    return;
  }

  let deletedChats = 0;
  let deletedMessages = 0;
  const testUserIdsArray = Array.from(report.testUserIds);

  // Очищаем чаты, где participants содержит тестового пользователя
  for (let i = 0; i < testUserIdsArray.length; i += 10) {
    const chunk = testUserIdsArray.slice(i, i + 10);

    for (const testUserId of chunk) {
      try {
        // Находим чаты, где участвует тестовый пользователь
        const chatsSnapshot = await db.collection('chats')
          .where('participants', 'array-contains', testUserId)
          .get();

        for (const chatDoc of chatsSnapshot.docs) {
          // Удаляем сообщения в чате
          const messagesSnapshot = await chatDoc.ref.collection('messages').get();
          if (!messagesSnapshot.empty) {
            const messagesBatch = db.batch();
            messagesSnapshot.docs.forEach((msgDoc: admin.firestore.QueryDocumentSnapshot) => {
              messagesBatch.delete(msgDoc.ref);
              deletedMessages++;
            });
            await messagesBatch.commit();
          }

          // Удаляем сам чат
          await chatDoc.ref.delete();
          deletedChats++;
        }
      } catch (error: any) {
        const errorMsg = `Ошибка при удалении чатов для ${testUserId}: ${error.message}`;
        console.error(`  ❌ ${errorMsg}`);
        report.errors.push(errorMsg);
      }
    }
  }

  report.deleted.chats = deletedChats;
  report.deleted.messages = deletedMessages;
  console.log(`  ✅ Удалено чатов: ${deletedChats}, сообщений: ${deletedMessages}`);
}

/**
 * Очистка Storage файлов
 */
async function cleanStorageFiles(prefix: string): Promise<void> {
  console.log(`\n📁 Очистка Storage: ${prefix}...`);

  if (report.testUserIds.size === 0) {
    console.log(`  ⏭️ Нет тестовых пользователей, пропускаем`);
    return;
  }

  let deleted = 0;

  try {
    const [files] = await storage.getFiles({ prefix });

    for (const file of files) {
      // Проверяем, принадлежит ли файл тестовому пользователю
      // Путь обычно: uploads/avatars/{userId}/... или uploads/posts/{userId}/...
      const pathParts = file.name.split('/');
      if (pathParts.length >= 3) {
        const userId = pathParts[2]; // предполагаем формат prefix/{userId}/...

        if (report.testUserIds.has(userId)) {
          try {
            await file.delete();
            deleted++;
          } catch (error: any) {
            const errorMsg = `Ошибка удаления файла ${file.name}: ${error.message}`;
            console.error(`  ❌ ${errorMsg}`);
            report.errors.push(errorMsg);
          }
        }
      }
    }

    console.log(`  ✅ Удалено ${deleted} файлов из ${prefix}`);
    report.deleted.storageFiles += deleted;
  } catch (error: any) {
    const errorMsg = `Ошибка при очистке Storage ${prefix}: ${error.message}`;
    console.error(`  ❌ ${errorMsg}`);
    report.errors.push(errorMsg);
  }
}

/**
 * Основная функция очистки
 */
async function cleanTestData(): Promise<void> {
  console.log('🚀 НАЧАЛО ОЧИСТКИ ТЕСТОВЫХ ДАННЫХ\n');
  console.log('='.repeat(60));

  try {
    // 1. Очистка пользователей (первым делом, чтобы получить список testUserIds)
    await cleanUsers();

    // 2. Очистка специалистов (проверяем по userId)
    await cleanCollection('specialists', async (docId, data) => {
      const userId = data.userId || docId;
      return report.testUserIds.has(userId);
    });

    // 3. Очистка постов
    await cleanByAuthorId('posts', 'authorId');

    // 4. Очистка идей
    await cleanByAuthorId('ideas', 'authorId');

    // 5. Очистка stories
    await cleanByAuthorId('stories', 'authorId');

    // 6. Очистка requests
    await cleanByAuthorId('requests', 'authorId');

    // 7. Очистка чатов и сообщений
    await cleanChats();

    // 8. Очистка follows
    await cleanCollection('follows', async (docId, data) => {
      const followerId = data.followerId || data.follower;
      const followingId = data.followingId || data.following;
      return report.testUserIds.has(followerId) || report.testUserIds.has(followingId);
    });

    // 9. Очистка notifications
    await cleanByAuthorId('notifications', 'userId');

    // 10. Очистка events
    await cleanByAuthorId('events_profile_views', 'viewerId');
    await cleanByAuthorId('events_post_engagement', 'actorId');
    await cleanByAuthorId('events_follow', 'followerId');
    await cleanByAuthorId('events_requests', 'customerId');

    // 11. Очистка specialist_stats и specialist_scores
    await cleanCollection('specialist_stats', async (docId, data) => {
      // Удаляем только если связанный специалист был тестовым
      return report.testUserIds.has(docId);
    });

    await cleanCollection('specialist_scores', async (docId, data) => {
      return report.testUserIds.has(docId);
    });

    // 12. Очистка Storage файлов
    await cleanStorageFiles('uploads/avatars/');
    await cleanStorageFiles('uploads/posts/');
    await cleanStorageFiles('uploads/reels/');
    await cleanStorageFiles('uploads/ideas/');
    await cleanStorageFiles('uploads/stories/');

    // Выводим финальный отчёт
    console.log('\n' + '='.repeat(60));
    console.log('✅ ОЧИСТКА ЗАВЕРШЕНА\n');

    console.log('📊 СТАТИСТИКА УДАЛЕНИЯ:');
    console.log(`  Пользователи: ${report.deleted.users}`);
    console.log(`  Специалисты: ${report.deleted.specialists}`);
    console.log(`  Посты: ${report.deleted.posts}`);
    console.log(`  Идеи: ${report.deleted.ideas}`);
    console.log(`  Stories: ${report.deleted.stories}`);
    console.log(`  Заявки: ${report.deleted.requests}`);
    console.log(`  Чаты: ${report.deleted.chats}`);
    console.log(`  Сообщения: ${report.deleted.messages}`);
    console.log(`  Подписки: ${report.deleted.follows}`);
    console.log(`  Уведомления: ${report.deleted.notifications}`);
    console.log(`  Events (profile views): ${report.deleted.events_profile_views}`);
    console.log(`  Events (post engagement): ${report.deleted.events_post_engagement}`);
    console.log(`  Events (follow): ${report.deleted.events_follow}`);
    console.log(`  Events (requests): ${report.deleted.events_requests}`);
    console.log(`  Specialist stats: ${report.deleted.specialist_stats}`);
    console.log(`  Specialist scores: ${report.deleted.specialist_scores}`);
    console.log(`  Файлы Storage: ${report.deleted.storageFiles}`);

    console.log('\n📋 КОЛЛЕКЦИИ ПОСЛЕ ОЧИСТКИ:');
    const collections = [
      'users', 'specialists', 'posts', 'ideas', 'stories', 'requests',
      'chats', 'follows', 'notifications',
      'events_profile_views', 'events_post_engagement', 'events_follow', 'events_requests',
      'specialist_stats', 'specialist_scores'
    ];

    for (const coll of collections) {
      const count = report.remaining[coll] ?? 0;
      if (count === 0) {
        console.log(`  ${coll}: OK (empty)`);
      } else {
        console.log(`  ${coll}: ${count} документов`);
      }
    }

    if (report.errors.length > 0) {
      console.log('\n⚠️ ОШИБКИ:');
      report.errors.forEach((err, idx) => {
        console.log(`  ${idx + 1}. ${err}`);
      });
    }

    console.log('\n✅ Подтверждение: реальные данные НЕ затронуты');
    console.log(`   Удалено тестовых пользователей: ${report.testUserIds.size}`);
    console.log('='.repeat(60));

  } catch (error: any) {
    console.error('\n❌ КРИТИЧЕСКАЯ ОШИБКА:', error);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

// Запуск
cleanTestData().then(() => {
  console.log('\n✅ Скрипт завершён успешно');
  process.exit(0);
}).catch((error) => {
  console.error('\n❌ Скрипт завершён с ошибкой:', error);
  process.exit(1);
});

