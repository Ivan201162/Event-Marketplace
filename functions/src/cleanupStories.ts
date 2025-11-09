import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();

/**
 * Автоматическое удаление истёкших сторис (каждые 10 минут)
 */
export const cleanupExpiredStories = functions.pubsub
  .schedule("every 15 minutes")
  .onRun(async (context) => {
    const db = admin.firestore();
    const storage = admin.storage();
    const now = admin.firestore.Timestamp.now();

    try {
      // Находим все сторис с expiresAt < now
      const expiredStories = await db
        .collection("stories")
        .where("expiresAt", "<", now)
        .limit(500)
        .get();

      if (expiredStories.empty) {
        functions.logger.info("No expired stories to clean up");
        return null;
      }

      functions.logger.info(`Found ${expiredStories.size} expired stories`);

      const batch = db.batch();
      let deletedCount = 0;

      for (const storyDoc of expiredStories.docs) {
        const storyData = storyDoc.data();
        const authorId = storyData.authorId;
        const storyId = storyDoc.id;
        const mediaUrl = storyData.mediaUrl as string;

        // Удаляем документ из Firestore
        batch.delete(storyDoc.ref);
        deletedCount++;

        // Удаляем файл из Storage
        if (mediaUrl) {
          try {
            // Извлекаем путь из URL
            const urlParts = mediaUrl.split("/o/");
            if (urlParts.length > 1) {
              const pathPart = urlParts[1].split("?")[0];
              const decodedPath = decodeURIComponent(pathPart);
              const fileRef = storage.bucket().file(decodedPath);
              
              await fileRef.delete().catch((err) => {
                functions.logger.warn(`Failed to delete file ${decodedPath}: ${err}`);
              });
            }
          } catch (err) {
            functions.logger.warn(`Error deleting storage file for story ${storyId}: ${err}`);
          }
        }
      }

      await batch.commit();
      functions.logger.info(`Deleted ${deletedCount} expired stories`);

      return null;
    } catch (error) {
      functions.logger.error("Error cleaning up expired stories:", error);
      throw error;
    }
  });

