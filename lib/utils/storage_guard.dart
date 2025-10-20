import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Returns FirebaseStorage instance on non-web platforms, otherwise null.
FirebaseStorage? getStorage() {
  if (kIsWeb) return null;
  return FirebaseStorage.instance;
}

/// Helper to safely execute storage actions only when storage is available.
T? withStorage<T>(T Function(FirebaseStorage storage) action) {
  final storage = getStorage();
  if (storage == null) return null;
  return action(storage);
}

