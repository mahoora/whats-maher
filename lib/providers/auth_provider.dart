import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  String get userId => _firebaseUser?.uid ?? '';

  AuthProvider() {
    FirebaseService.auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _appUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    final doc = await FirebaseService.users.doc(uid).get();
    if (doc.exists) {
      _appUser = AppUser.fromMap(doc.data() as Map<String, dynamic>);
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await FirebaseService.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await FirebaseService.signUp(email, password);
      final uid = cred.user!.uid;
      final userData = {
        'uid': uid,
        'email': email,
        'displayName': name,
        'photoUrl': null,
        'status': 'مرحباً، أنا على واتساب',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseService.users.doc(uid).set(userData);
      _appUser = AppUser.fromMap({...userData, 'lastSeen': DateTime.now(), 'createdAt': DateTime.now()});
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setOnlineStatus(bool online) async {
    if (_firebaseUser == null) return;
    try {
      await FirebaseService.users.doc(_firebaseUser!.uid).update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    try { await setOnlineStatus(false); } catch (_) {}
    await FirebaseService.signOut();
    _firebaseUser = null;
    _appUser = null;
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password': return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password': return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'invalid-email': return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'too-many-requests': return 'تم حظر الطلب مؤقتاً، حاول لاحقاً';
      default: return 'خطأ: $code';
    }
  }
}
