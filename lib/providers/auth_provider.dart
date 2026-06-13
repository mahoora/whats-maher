import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;
  ConfirmationResult? _confirmationResult;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  String get userId => _firebaseUser?.uid ?? '';
  bool get otpSent => _confirmationResult != null;
  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  AuthProvider() {
    FirebaseService.auth.authStateChanges().listen((User? user) async {
      try {
        if (user != null) {
          _firebaseUser = user;
          try {
            final uid = user.uid;
            final doc = await FirebaseService.users.doc(uid).get();
            if (doc.exists) {
              _appUser = AppUser.fromMap(doc.data() as Map<String, dynamic>);
              _isNewUser = false;
            } else {
              _appUser = AppUser(uid: uid, phoneNumber: user.phoneNumber ?? '', displayName: '');
              _isNewUser = true;
            }
          } catch (_) {
            _appUser ??= AppUser(uid: user.uid, phoneNumber: user.phoneNumber ?? '', displayName: '');
            _isNewUser = true;
          }
        } else {
          _firebaseUser = null;
          _appUser = null;
          _confirmationResult = null;
          _isNewUser = false;
        }
      } catch (_) {}
      notifyListeners();
    });
  }

  Future<void> sendOtp(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    _isLoading = true;
    _error = null;
    _confirmationResult = null;
    notifyListeners();

    try {
      final result = await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
      _confirmationResult = result;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'فشل إرسال رمز التحقق';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> verifyOtp(String smsCode) async {
    if (_confirmationResult == null || smsCode.isEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _confirmationResult!.confirm(smsCode);
      _confirmationResult = null;
      for (int i = 0; i < 20; i++) {
        if (_firebaseUser != null) break;
        final user = FirebaseService.auth.currentUser;
        if (user != null) {
          _firebaseUser = user;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (_firebaseUser != null) {
        final doc = await FirebaseService.users.doc(_firebaseUser!.uid).get();
        if (doc.exists) {
          _appUser = AppUser.fromMap(doc.data() as Map<String, dynamic>);
          _isNewUser = false;
        } else {
          _appUser = AppUser(uid: _firebaseUser!.uid, phoneNumber: _firebaseUser!.phoneNumber ?? '', displayName: '');
          _isNewUser = true;
        }
      }
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
    } catch (e) {
      _error = 'رمز التحقق غير صحيح';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile(String displayName) async {
    if (_firebaseUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _firebaseUser!.uid;
      final userData = {
        'uid': uid,
        'phoneNumber': _firebaseUser!.phoneNumber ?? '',
        'displayName': displayName,
        'photoUrl': null,
        'status': 'مرحباً، أنا على واتساب',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseService.users.doc(uid).set(userData);
      _isNewUser = false;
      _appUser = AppUser(
        uid: uid,
        phoneNumber: _firebaseUser!.phoneNumber ?? '',
        displayName: displayName,
        status: 'مرحباً، أنا على واتساب',
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      _error = 'فشل إنشاء الحساب';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setOnlineStatus(bool online) async {
    if (_firebaseUser == null) return;
    await FirebaseService.users.doc(_firebaseUser!.uid).update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    await setOnlineStatus(false);
    await FirebaseService.signOut();
    _appUser = null;
    _confirmationResult = null;
    _isNewUser = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number': return 'رقم الهاتف غير صحيح';
      case 'too-many-requests': return 'تم حظر الطلب مؤقتاً، حاول لاحقاً';
      case 'invalid-verification-code': return 'رمز التحقق غير صحيح';
      case 'session-expired': return 'انتهت صلاحية الجلسة، أعد المحاولة';
      case 'captcha-check-failed': return 'فشل التحقق الأمني، حاول مرة أخرى';
      case 'web-context-already-presented': return '';
      case 'operation-not-allowed': return 'مصادقة الهاتف غير مفعلة، تأكد من Firebase Console';
      default: return 'خطأ: $code';
    }
  }
}
