import 'dart:js_interop_unsafe';
import 'dart:js_interop';

Future<String?> sendPhoneOtpJs(String phone) async {
  final phoneAuth = globalThis['_phoneAuth'.toJS];
  if (phoneAuth == null) return 'خطأ: Firebase غير محمّل';
  try {
    final promise = phoneAuth.call('sendOtp'.toJS, phone.toJS);
    final result = await (promise as JSPromise).toDart;
    final s = result?.dartify;
    return s as String?;
  } catch (e) {
    return 'خطأ: $e';
  }
}

Future<String?> verifyOtpJs(String code) async {
  final phoneAuth = globalThis['_phoneAuth'.toJS];
  if (phoneAuth == null) return 'خطأ: Firebase غير محمّل';
  try {
    final promise = phoneAuth.call('verifyOtp'.toJS, code.toJS);
    await (promise as JSPromise).toDart;
    return null;
  } catch (e) {
    return 'خطأ: $e';
  }
}