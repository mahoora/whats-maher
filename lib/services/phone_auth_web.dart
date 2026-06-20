import 'dart:html' as html;

Future<String?> sendPhoneOtpJs(String phone) async {
  final phoneAuth = html.window['_phoneAuth'] as dynamic;
  if (phoneAuth == null) return 'خطأ: Firebase غير محمّل';
  try {
    final dynamic promise = phoneAuth.sendOtp(phone);
    final dynamic result = await promise;
    return result as String?;
  } catch (e) {
    return 'خطأ: $e';
  }
}

Future<String?> verifyOtpJs(String code) async {
  final phoneAuth = html.window['_phoneAuth'] as dynamic;
  if (phoneAuth == null) return 'خطأ: Firebase غير محمّل';
  try {
    final dynamic promise = phoneAuth.verifyOtp(code);
    final dynamic result = await promise;
    return result as String?;
  } catch (e) {
    return 'خطأ: $e';
  }
}
