import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();

export const wipeTestUser = functions.https.onCall(async (data, context) => {
  // Защита: разрешаем только если пришёл валидный токен клиента
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "No auth");
  }
  const targetUid: string = data?.uid;
  const hard = !!data?.hard; // true = удаляем auth; false = только данные
  if (!targetUid) {
    throw new functions.https.HttpsError("invalid-argument", "uid required");
  }

  // Блокируем прод-удаление случайных пользователей
  const projectId = process.env.GCLOUD_PROJECT || "";
  const allow = process.env.ALLOW_TEST_WIPE === "1";
  if (!allow) {
    throw new functions.https.HttpsError("failed-precondition", "Wipe disabled");
  }

  // Удаляем документы и подколлекции самых крупных разделов
  const db = admin.firestore();

  const batchDeleteCollection = async (path: string) => {
    const col = db.collection(path);
    const snap = await col.limit(500).get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach(d => batch.delete(d.ref));
    await batch.commit();
    // Рекурсия (пока не очистится)
    return batchDeleteCollection(path);
  };

  const userDocRef = db.collection("users").doc(targetUid);

  // Перечень коллекций, где могут лежать данные пользователя
  const paths = [
    `users/${targetUid}/saved_filters`,
    `chats`, // будем фильтровать по участнику
    `messages`, // фильтрация по chatId ниже
    `reviews`,
    `requests`,
    `notifications`,
    `stories`,
    `posts`,
    `reels`,
    `specialist_pricing/${targetUid}/base`,
    `specialist_pricing/${targetUid}/special_dates`,
    `bookings`,
    `specialist_calendar/${targetUid}/days`,
    `ideas`,
    `followers`,
    `following`,
  ];

  // Точечные удаления (по полям)
  // Удаляем чаты, где участник targetUid
  const chats = await db.collection("chats").where("participants", "array-contains", targetUid).get();
  for (const doc of chats.docs) {
    // удалить сообщения чата
    await batchDeleteCollection(`chats/${doc.id}/messages`);
    await doc.ref.delete();
  }

  // Удаляем все сущности, где автор — targetUid
  const deleteWhere = async (col: string, field="authorId") => {
    let snap = await db.collection(col).where(field, "==", targetUid).limit(500).get();
    while (!snap.empty) {
      const batch = db.batch();
      snap.docs.forEach(d => batch.delete(d.ref));
      await batch.commit();
      snap = await db.collection(col).where(field, "==", targetUid).limit(500).get();
    }
  };

  await deleteWhere("posts");
  await deleteWhere("reels");
  await deleteWhere("stories");
  await deleteWhere("reviews", "authorId");
  await deleteWhere("requests", "createdBy");
  await deleteWhere("ideas", "authorId");
  await deleteWhere("notifications", "userId");
  await deleteWhere("bookings", "clientId");
  await deleteWhere("bookings", "specialistId");

  // Календарь/прайсы
  await batchDeleteCollection(`specialist_calendar/${targetUid}/days`);
  await batchDeleteCollection(`specialist_pricing/${targetUid}/base`);
  await batchDeleteCollection(`specialist_pricing/${targetUid}/special_dates`);

  // Документ пользователя
  await userDocRef.delete().catch(()=>{});

  // Удаляем учётку (если hard)
  if (hard) {
    try { await admin.auth().deleteUser(targetUid); } catch {}
  }

  return { ok: true };
});

