import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  fb_auth.User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _error;
  String? _verificationId;

  fb_auth.User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get userId => _firebaseUser?.uid ?? '';
  String? get verificationId => _verificationId;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    FirebaseService.auth.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _ensureUserDoc(user.uid, user.email ?? user.phoneNumber ?? '');
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _ensureUserDoc(String uid, String identifier) async {
    try {
      final doc = await FirebaseService.users.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _appUser = AppUser.fromMap(data);
      } else {
        final name = identifier.contains('@') ? identifier.split('@').first : identifier;
        final defaultData = {
          'uid': uid,
          'email': _firebaseUser?.email ?? '',
          'phoneNumber': _firebaseUser?.phoneNumber ?? '',
          'displayName': name,
          'photoUrl': null,
          'status': 'مرحباً، أنا على واتساب',
          'isOnline': true,
          'lastSeen': DateTime.now(),
          'createdAt': DateTime.now(),
        };
        await FirebaseService.users.doc(uid).set(defaultData);
        _appUser = AppUser.fromMap(defaultData);
      }
    } catch (e) {
      debugPrint('_ensureUserDoc error: $e');
    }
  }

  Future<void> reloadProfile() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    await _ensureUserDoc(uid, _firebaseUser?.email ?? _firebaseUser?.phoneNumber ?? '');
    notifyListeners();
  }

  /// Email/password login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await FirebaseService.auth.signInWithEmailAndPassword(email: email, password: password);
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Email/password register
  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await FirebaseService.auth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final userData = {
        'uid': uid,
        'email': email,
        'displayName': name,
        'photoUrl': null,
        'status': 'مرحباً، أنا على واتساب',
        'isOnline': true,
        'lastSeen': DateTime.now(),
        'createdAt': DateTime.now(),
      };
      await FirebaseService.users.doc(uid).set(userData);
      _appUser = AppUser.fromMap(userData);
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Phone OTP
  Future<void> sendPhoneOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();
    try {
      await FirebaseService.auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (cred) async {
          await FirebaseService.auth.signInWithCredential(cred);
        },
        verificationFailed: (e) {
          _error = e.message ?? 'فشل إرسال رمز التحقق';
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (vid, _) {
          _verificationId = vid;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (vid) {
          if (_verificationId == null) {
            _error = 'انتهت مهلة التحقق';
            _isLoading = false;
            notifyListeners();
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _error = 'حدث خطأ: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String code) async {
    if (_verificationId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseService.auth.signInWithCredential(cred);
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = e.message ?? 'رمز غير صحيح';
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resendOtp(String phoneNumber) async {
    await sendPhoneOtp(phoneNumber);
  }

  Future<void> setOnlineStatus(bool online) async {
    if (_firebaseUser == null) return;
    try {
      await FirebaseService.users.doc(_firebaseUser!.uid).update({
        'isOnline': online,
        'lastSeen': DateTime.now(),
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    _verificationId = null;
    try { await setOnlineStatus(false); } catch (_) {}
    await FirebaseService.auth.signOut();
    _firebaseUser = null;
    _appUser = null;
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password': return 'كلمة المرور غير صحيحة';
      case 'invalid-email': return 'البريد الإلكتروني غير صحيح';
      case 'email-already-in-use': return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'weak-password': return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'too-many-requests': return 'محاولات كثيرة، حاول لاحقاً';
      case 'invalid-verification-code': return 'رمز التحقق غير صحيح';
      case 'invalid-phone-number': return 'رقم الهاتف غير صحيح';
      default: return 'خطأ: $code';
    }
  }
}
