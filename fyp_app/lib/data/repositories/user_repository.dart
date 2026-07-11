import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> saveUserProfile({
    required String name,
    required String email,
  }) async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).set({
      'uid': _uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_uid == null) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    return doc.data();
  }

  Future<void> saveActivity({
    required String title,
    required String type,
  }) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('activity')
        .add({
      'title': title,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    if (_uid == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('activity')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveChatMessage({
    required String message,
    required bool isAi,
    required String time,
  }) async {
    if (_uid == null) return;
    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chat_history')
        .add({
      'message': message,
      'isAi': isAi,
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    if (_uid == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chat_history')
        .orderBy('createdAt', descending: false)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> clearChatHistory() async {
    if (_uid == null) return;
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chat_history')
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
