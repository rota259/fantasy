import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// الدخول بجوجل (مجاني): جوجل بيدّينا idToken، و Supabase بيعمل الحساب أو يدخّل بيه.
///
/// [webClientId] = "Web client ID" من Google Cloud Console (مش سر) — لو فاضي زرار جوجل مش بيظهر.
/// الخطوات في docs/GOOGLE_SIGN_IN.md.
abstract final class GoogleAuth {
  GoogleAuth._();

  static const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '621117558856-acg6491pssv8is040r5a54l13rd7dqna.apps.googleusercontent.com',
  );

  static bool get isEnabled => webClientId.isNotEmpty;

  static String? _rawNonce;

  /// بيفتح اختيار حساب جوجل — بيرجّع (idToken, nonce) أو null لو اليوزر لغى.
  static Future<({String idToken, String nonce})?> signIn() async {
    final signIn = GoogleSignIn.instance;
    if (_rawNonce == null) {
      // nonce: جوجل بياخد النسخة المشفّرة، و Supabase بيتأكد منها بالأصلية (ضد إعادة استخدام التوكن)
      final rand = Random.secure();
      _rawNonce = base64Url.encode(List<int>.generate(32, (_) => rand.nextInt(256)));
      await signIn.initialize(serverClientId: webClientId, nonce: sha256.convert(utf8.encode(_rawNonce!)).toString());
    }
    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return null;
      return (idToken: idToken, nonce: _rawNonce!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  static Future<void> signOut() async {
    if (_rawNonce == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
