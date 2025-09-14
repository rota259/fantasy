import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// تسجيل مستخدم جديد
  Future<UserModel> register(UserModel user, String password) async {
    // إنشاء الحساب في Firebase Auth
    final result = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    final uid = result.user!.uid;
    final newUser = user.copyWith(uid: uid);

    // تخزين بيانات المستخدم في Firestore
    await _firestore.collection('users').doc(uid).set(newUser.toMap());

    // حفظ UID محليًا لتسجيل الدخول التلقائي
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);

    return newUser;
  }

  /// تسجيل الدخول بالإيميل أو رقم الموبايل
  Future<UserModel> signIn(String input, String password) async {
    String email = input;

    // لو المستخدم كتب رقم موبايل بدل الإيميل
    if (!input.contains('@')) {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: input)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception("رقم الموبايل غير مسجل");
      }

      email = query.docs.first['email'];
    }

    // تسجيل الدخول باستخدام الإيميل
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = result.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception("بيانات المستخدم غير موجودة");

    final user = UserModel.fromMap(doc.data()!);

    // حفظ UID محليًا
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);

    return user;
  }

  /// التحقق من تسجيل دخول تلقائي
  Future<UserModel?> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid != null) {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    }
    return null;
  }

  /// تسجيل خروج
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
  }
}
