import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/repositories/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  String? europeanTeam;
  String? localTeam;
  String? photoUrl;

  final europeanTeams = [
    "Real Madrid",
    "Barcelona",
    "Manchester City",
    "Liverpool",
    "Bayern Munich",
    "Arsenal",
    "Juventus",
    "PSG",
  ];

  final localTeams = [
    "الأهلي",
    "الزمالك",
    "بيراميدز",
    "الإسماعيلي",
    "الاتحاد السكندري",
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phone);
    europeanTeam = widget.user.favEuropeanTeam;
    localTeam = widget.user.favLocalTeam;
    photoUrl = widget.user.photoUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked != null) {
        final uploadedUrl = await UserRepository.uploadToCloudinary(
          picked.path,
        );
        setState(() => photoUrl = uploadedUrl);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("لم يتم اختيار صورة")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء اختيار الصورة: $e")),
      );
    }
  }

  void _handleImageTap() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text("عرض الصورة"),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(child: Image.network(photoUrl!)),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("اختيار من المعرض"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("التقاط بالكاميرا"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("إزالة الصورة"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => photoUrl = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickTeam(List<String> teams, bool isEuropean) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        children: teams.map((team) {
          return ListTile(
            title: Text(team),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                if (isEuropean) {
                  europeanTeam = team;
                } else {
                  localTeam = team;
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final updatedUser = widget.user.copyWith(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      photoUrl: photoUrl,
      favEuropeanTeam: europeanTeam,
      favLocalTeam: localTeam,
    );

    await UserRepository.updateUser(updatedUser);
    Navigator.pop(context, updatedUser);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,

      filled: true,
      fillColor: AppColors.surface.withOpacity(0.6),
      labelStyle: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.success, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      appBar: AppBar(
        title: const Text(
          "تعديل الملف الشخصي",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _handleImageTap,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surface,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: AppColors.textSecondary,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("الاسم"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("البريد الإلكتروني"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              controller: phoneController,
              decoration: _inputDecoration("رقم الموبايل"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "الفريق الأوروبي المفضل",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                europeanTeam ?? "غير محدد",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.edit, color: AppColors.textPrimary),
              onTap: () => _pickTeam(europeanTeams, true),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "الفريق المحلي المفضل",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                localTeam ?? "غير محدد",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.edit, color: AppColors.textPrimary),
              onTap: () => _pickTeam(localTeams, false),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: AppColors.buttonText),
              label: const Text("حفظ التعديلات"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.buttonText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
