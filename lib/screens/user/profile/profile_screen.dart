import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fantasy_5omasi/cubits/auth/auth_cubit.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/screens/user/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;

    if (state is! AuthSuccess) {
      return const Scaffold(body: Center(child: Text("لا يوجد بيانات مستخدم")));
    }

    final UserModel user = state.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundSoft, // ← خلفية مختلفة
      appBar: AppBar(
        title: const Text(
          "الملف الشخصي",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundSoft, // ← لون مميز للـ AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textPrimary),
            onPressed: () async {
              final updatedUser = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: user),
                ),
              );

              if (updatedUser != null && updatedUser is UserModel) {
                context.read<AuthCubit>().emit(AuthSuccess(updatedUser));
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Icon(Icons.person, size: 60, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 20),
            _infoCard(Icons.person, "الاسم", user.name),
            _infoCard(Icons.email, "البريد الإلكتروني", user.email),
            _infoCard(Icons.phone, "رقم الموبايل", user.phone),
            _infoCard(
              Icons.shield,
              "الدور",
              user.role == 'manager' ? "مدير فريق" : "لاعب عادي",
            ),
            _infoCard(
              Icons.flag,
              "الفريق الأوروبي",
              user.favEuropeanTeam ?? "غير محدد",
            ),
            _infoCard(
              Icons.sports_soccer,
              "الفريق المحلي",
              user.favLocalTeam ?? "غير محدد",
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AuthCubit>().signOut();
                Navigator.pushReplacementNamed(context, '/auth');
              },
              icon: const Icon(Icons.logout, color: Colors.black),
              label: const Text(
                "تسجيل الخروج",
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
