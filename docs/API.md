# API Documentation

## Обзор

Event Marketplace App использует Firebase как backend-as-a-service, предоставляя REST API через Firebase Functions и прямые клиентские SDK для Firestore, Authentication и Storage.

## Аутентификация

### Firebase Authentication

#### Регистрация пользователя

```dart
// Email/Password регистрация
Future<User?> signUpWithEmailAndPassword({
  required String email,
  required String password,
  required String name,
  String? phone,
}) async {
  try {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Обновление профиля
    await credential.user?.updateDisplayName(name);
    if (phone != null) {
      await credential.user?.updatePhoneNumber(phone);
    }
    
    return credential.user;
  } on FirebaseAuthException catch (e) {
    throw AuthException(_getAuthErrorMessage(e.code));
  }
}
```

#### Вход в систему

```dart
// Email/Password вход
Future<User?> signInWithEmailAndPassword({
  required String email,
  required String password,
}) async {
  try {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  } on FirebaseAuthException catch (e) {
    throw AuthException(_getAuthErrorMessage(e.code));
  }
}

// Google Sign-In
Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    
    final GoogleSignInAuthentication googleAuth = 
        await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user;
  } catch (e) {
    throw AuthException('Ошибка входа через Google: $e');
  }
}
```

#### Выход из системы

```dart
Future<void> signOut() async {
  await Future.wait([
    _firebaseAuth.signOut(),
    _googleSignIn.signOut(),
  ]);
}
```

## Firestore Database

### Коллекции

#### Users Collection

```dart
// Структура документа пользователя
{
  "id": "user123",
  "email": "user@example.com",
  "name": "Иван Иванов",
  "phone": "+7 999 123 45 67",
  "avatar": "https://storage.googleapis.com/...",
  "role": "customer", // "customer" | "specialist" | "admin"
  "isVerified": true,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z",
  "preferences": {
    "language": "ru",
    "notifications": true,
    "theme": "system"
  }
}
```

#### Events Collection

```dart
// Структура документа события
{
  "id": "event123",
  "title": "Свадебная церемония",
  "description": "Организация свадебной церемонии",
  "category": "wedding",
  "location": {
    "address": "Москва, ул. Тверская, 1",
    "coordinates": {
      "latitude": 55.7558,
      "longitude": 37.6176
    }
  },
  "date": "2024-06-15T18:00:00Z",
  "endDate": "2024-06-15T23:00:00Z",
  "price": 50000,
  "currency": "RUB",
  "maxParticipants": 100,
  "organizerId": "user123",
  "specialistId": "specialist456",
  "status": "active", // "active" | "cancelled" | "completed"
  "isPublic": true,
  "images": ["https://storage.googleapis.com/..."],
  "requirements": ["Дресс-код: вечерний"],
  "contactInfo": {
    "phone": "+7 999 123 45 67",
    "email": "organizer@example.com"
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

#### Bookings Collection

```dart
// Структура документа бронирования
{
  "id": "booking123",
  "eventId": "event123",
  "customerId": "user123",
  "specialistId": "specialist456",
  "organizerId": "user123",
  "status": "pending", // "pending" | "confirmed" | "cancelled" | "completed"
  "bookingDate": "2024-01-01T00:00:00Z",
  "eventDate": "2024-06-15T18:00:00Z",
  "participantsCount": 2,
  "specialRequests": "Нужен переводчик",
  "price": 50000,
  "currency": "RUB",
  "paymentStatus": "pending", // "pending" | "paid" | "refunded"
  "prepaymentPaid": false,
  "isPrepayment": true,
  "isFinalPayment": true,
  "dueDate": "2024-06-01T00:00:00Z",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### CRUD операции

#### Создание события

```dart
Future<Event> createEvent(Event event) async {
  try {
    final docRef = await _firestore.collection('events').add(event.toMap());
    return event.copyWith(id: docRef.id);
  } on FirebaseException catch (e) {
    throw FirestoreException('Ошибка создания события: ${e.message}');
  }
}
```

#### Получение событий

```dart
// Получение всех активных событий
Future<List<Event>> getActiveEvents() async {
  try {
    final snapshot = await _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .where('isPublic', isEqualTo: true)
        .orderBy('date')
        .get();
    
    return snapshot.docs
        .map((doc) => Event.fromDocument(doc))
        .toList();
  } on FirebaseException catch (e) {
    throw FirestoreException('Ошибка загрузки событий: ${e.message}');
  }
}

// Получение событий с пагинацией
Future<List<Event>> getEvents({
  int limit = 20,
  DocumentSnapshot? lastDocument,
}) async {
  try {
    Query query = _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .orderBy('date')
        .limit(limit);
    
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Event.fromDocument(doc))
        .toList();
  } on FirebaseException catch (e) {
    throw FirestoreException('Ошибка загрузки событий: ${e.message}');
  }
}
```

#### Обновление события

```dart
Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
  try {
    await _firestore
        .collection('events')
        .doc(eventId)
        .update({
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  } on FirebaseException catch (e) {
    throw FirestoreException('Ошибка обновления события: ${e.message}');
  }
}
```

#### Удаление события

```dart
Future<void> deleteEvent(String eventId) async {
  try {
    await _firestore.collection('events').doc(eventId).delete();
  } on FirebaseException catch (e) {
    throw FirestoreException('Ошибка удаления события: ${e.message}');
  }
}
```

### Real-time обновления

```dart
// Поток событий в реальном времени
Stream<List<Event>> getEventsStream() {
  return _firestore
      .collection('events')
      .where('status', isEqualTo: 'active')
      .orderBy('date')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Event.fromDocument(doc))
          .toList());
}

// Поток бронирований пользователя
Stream<List<Booking>> getUserBookingsStream(String userId) {
  return _firestore
      .collection('bookings')
      .where('customerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Booking.fromDocument(doc))
          .toList());
}
```

## Firebase Storage

### Загрузка файлов

```dart
// Загрузка изображения события
Future<String> uploadEventImage(File imageFile, String eventId) async {
  try {
    final fileName = 'events/$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(fileName);
    
    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'eventId': eventId,
          'uploadedBy': _auth.currentUser?.uid ?? '',
        },
      ),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  } on FirebaseException catch (e) {
    throw StorageException('Ошибка загрузки изображения: ${e.message}');
  }
}

// Загрузка аватара пользователя
Future<String> uploadUserAvatar(File imageFile, String userId) async {
  try {
    final fileName = 'avatars/$userId.jpg';
    final ref = _storage.ref().child(fileName);
    
    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
        },
      ),
    );
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  } on FirebaseException catch (e) {
    throw StorageException('Ошибка загрузки аватара: ${e.message}');
  }
}
```

### Удаление файлов

```dart
Future<void> deleteFile(String fileUrl) async {
  try {
    final ref = _storage.refFromURL(fileUrl);
    await ref.delete();
  } on FirebaseException catch (e) {
    throw StorageException('Ошибка удаления файла: ${e.message}');
  }
}
```

## Firebase Functions

### Cloud Functions

#### Создание бронирования

```javascript
// functions/src/booking.js
exports.createBooking = functions.https.onCall(async (data, context) => {
  // Проверка аутентификации
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Пользователь не аутентифицирован');
  }
  
  const { eventId, participantsCount, specialRequests } = data;
  
  // Валидация данных
  if (!eventId || !participantsCount) {
    throw new functions.https.HttpsError('invalid-argument', 'Недостаточно данных');
  }
  
  try {
    // Получение события
    const eventDoc = await admin.firestore().collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Событие не найдено');
    }
    
    const event = eventDoc.data();
    
    // Создание бронирования
    const bookingData = {
      eventId,
      customerId: context.auth.uid,
      specialistId: event.specialistId,
      organizerId: event.organizerId,
      status: 'pending',
      bookingDate: admin.firestore.FieldValue.serverTimestamp(),
      eventDate: event.date,
      participantsCount,
      specialRequests: specialRequests || '',
      price: event.price,
      currency: event.currency || 'RUB',
      paymentStatus: 'pending',
      prepaymentPaid: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    const bookingRef = await admin.firestore().collection('bookings').add(bookingData);
    
    // Отправка уведомления организатору
    await sendNotificationToUser(event.organizerId, {
      title: 'Новое бронирование',
      body: `Получено новое бронирование для события "${event.title}"`,
      data: { bookingId: bookingRef.id, eventId },
    });
    
    return { bookingId: bookingRef.id };
  } catch (error) {
    console.error('Ошибка создания бронирования:', error);
    throw new functions.https.HttpsError('internal', 'Внутренняя ошибка сервера');
  }
});
```

#### Обработка платежей

```javascript
// functions/src/payment.js
exports.processPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Пользователь не аутентифицирован');
  }
  
  const { bookingId, paymentMethod, amount } = data;
  
  try {
    // Получение бронирования
    const bookingDoc = await admin.firestore().collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Бронирование не найдено');
    }
    
    const booking = bookingDoc.data();
    
    // Проверка прав доступа
    if (booking.customerId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Нет прав для обработки этого платежа');
    }
    
    // Имитация обработки платежа (в реальном приложении здесь будет интеграция с платежной системой)
    const paymentResult = await processPaymentWithProvider({
      amount,
      currency: booking.currency,
      paymentMethod,
      bookingId,
    });
    
    if (paymentResult.success) {
      // Обновление статуса бронирования
      await admin.firestore().collection('bookings').doc(bookingId).update({
        paymentStatus: 'paid',
        prepaymentPaid: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Создание записи о платеже
      await admin.firestore().collection('payments').add({
        bookingId,
        customerId: context.auth.uid,
        specialistId: booking.specialistId,
        amount,
        currency: booking.currency,
        paymentMethod,
        status: 'completed',
        transactionId: paymentResult.transactionId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: true, transactionId: paymentResult.transactionId };
    } else {
      throw new functions.https.HttpsError('failed-precondition', 'Ошибка обработки платежа');
    }
  } catch (error) {
    console.error('Ошибка обработки платежа:', error);
    throw new functions.https.HttpsError('internal', 'Внутренняя ошибка сервера');
  }
});
```

### HTTP Functions

```javascript
// functions/src/webhook.js
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  
  try {
    const { bookingId, status, transactionId } = req.body;
    
    // Обновление статуса платежа
    await admin.firestore().collection('bookings').doc(bookingId).update({
      paymentStatus: status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    res.status(200).send('OK');
  } catch (error) {
    console.error('Ошибка webhook:', error);
    res.status(500).send('Internal Server Error');
  }
});
```

## Обработка ошибок

### Типы ошибок

```dart
// Базовый класс для ошибок API
abstract class ApiException implements Exception {
  final String message;
  final String? code;
  
  const ApiException(this.message, [this.code]);
  
  @override
  String toString() => 'ApiException: $message';
}

// Специфичные типы ошибок
class AuthException extends ApiException {
  const AuthException(super.message, [super.code]);
}

class FirestoreException extends ApiException {
  const FirestoreException(super.message, [super.code]);
}

class StorageException extends ApiException {
  const StorageException(super.message, [super.code]);
}

class NetworkException extends ApiException {
  const NetworkException(super.message, [super.code]);
}
```

### Обработка в сервисах

```dart
class EventService {
  Future<List<Event>> getEvents() async {
    try {
      // API вызов
      return await _repository.getEvents();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw FirestoreException('Нет прав доступа к событиям');
        case 'unavailable':
          throw NetworkException('Сервис временно недоступен');
        default:
          throw FirestoreException('Ошибка загрузки событий: ${e.message}');
      }
    } on SocketException {
      throw NetworkException('Нет подключения к интернету');
    } catch (e) {
      throw ApiException('Неизвестная ошибка: $e');
    }
  }
}
```

## Безопасность

### Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и обновлять только свой профиль
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // События доступны для чтения всем аутентифицированным пользователям
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                       request.auth.uid == resource.data.organizerId;
      allow update: if request.auth != null && 
                       (request.auth.uid == resource.data.organizerId ||
                        request.auth.uid == resource.data.specialistId);
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.organizerId;
    }
    
    // Бронирования доступны только участникам
    match /bookings/{bookingId} {
      allow read, write: if request.auth != null && 
                            (request.auth.uid == resource.data.customerId ||
                             request.auth.uid == resource.data.specialistId ||
                             request.auth.uid == resource.data.organizerId);
    }
  }
}
```

### Storage Security Rules

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Аватары пользователей
    match /avatars/{userId}.{extension} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Изображения событий
    match /events/{eventId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Мониторинг и аналитика

### Логирование

```dart
class ApiLogger {
  static void logApiCall(String endpoint, Map<String, dynamic>? params, Duration duration) {
    SafeLog.info('API Call: $endpoint', {
      'params': params,
      'duration_ms': duration.inMilliseconds,
    });
  }
  
  static void logError(String endpoint, dynamic error, StackTrace? stackTrace) {
    SafeLog.error('API Error: $endpoint', error, stackTrace);
  }
}
```

### Метрики производительности

```dart
class ApiMetrics {
  static Future<T> measureApiCall<T>(
    String operation,
    Future<T> Function() apiCall,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await apiCall();
      stopwatch.stop();
      
      // Отправка метрики в Firebase Performance
      final trace = FirebasePerformance.instance.newTrace('api_$operation');
      await trace.start();
      trace.setMetric('duration_ms', stopwatch.elapsedMilliseconds);
      await trace.stop();
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Логирование ошибки
      SafeLog.error('API Error in $operation', e);
      rethrow;
    }
  }
}
```

## Заключение

API Event Marketplace App построен на основе Firebase сервисов, обеспечивая:

- **Масштабируемость** - Автоматическое масштабирование Firebase
- **Безопасность** - Встроенная аутентификация и авторизация
- **Real-time** - Синхронизация данных в реальном времени
- **Надежность** - Высокая доступность и отказоустойчивость
- **Производительность** - Оптимизированные запросы и кэширование

Эта архитектура позволяет быстро разрабатывать и развертывать новые функции, обеспечивая при этом высокое качество и безопасность API.
