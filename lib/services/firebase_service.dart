import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseStorage get storage => _storage;

  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get chats => _firestore.collection('chats');
  static CollectionReference messages(String chatId) =>
      _firestore.collection('chats').doc(chatId).collection('messages');

  static Future<void> signOut() => _auth.signOut();

  static Future<String> uploadImage(String path, List<int> data) async {
    final ref = _storage.ref().child(path);
    await ref.putData(Uint8List.fromList(data));
    return await ref.getDownloadURL();
  }

  static String formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'أمس';
    return '${dt.day}/${dt.month}';
  }
}
