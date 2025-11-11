import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  Future<bool> isProfileComplete(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() ?? {};

      return (data['firstName']?.toString().isNotEmpty ?? false) &&
          (data['lastName']?.toString().isNotEmpty ?? false) &&
          (data['city']?.toString().isNotEmpty ?? false);
    } catch (e) {
      return false;
    }
  }
}
