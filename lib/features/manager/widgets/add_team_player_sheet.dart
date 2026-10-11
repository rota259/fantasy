import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/box_field.dart';
import '../../../core/widgets/motion.dart';

/// في الخماسي مفيش غير حارس ولاعب (اللاعب بيتخزّن FWD).
const _positions = [('FWD', 'لاعب'), ('GK', 'حارس')];

/// لاعب جديد: الاسم · حارس ولا لاعب · صورته (اختياري).
typedef NewTeamPlayer = ({String name, String position, Uint8List? photo, String? photoExt});

/// (مدير) شيت "ضيف لاعب" لفريق — بيرجّع الاسم والمركز والصورة لو اختارها.
Future<NewTeamPlayer?> showAddTeamPlayerSheet(BuildContext context, String team) {
  return showModalBottomSheet<NewTeamPlayer>(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => _Sheet(team: team),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.team});
  final String team;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _name = TextEditingController();
  String _pos = 'FWD';
  Uint8List? _photo;
  String? _ext;

  Future<void> _pickPhoto() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photo = bytes;
      _ext = f.name.contains('.') ? f.name.split('.').last : 'jpg';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ضيف لاعب لـ ${widget.team}', style: AppText.h(15)),
              const SizedBox(height: 12),
              // صورة اللاعب (اختياري) — بتظهر في التشكيلات وتشكيلة الجولة
              Center(
                child: Pressable(
                  onTap: _pickPhoto,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.accent100,
                        backgroundImage: _photo == null ? null : MemoryImage(_photo!),
                        child: _photo == null ? Icon(Icons.add_a_photo_outlined, color: AppColors.accent) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _photo == null ? 'ضيف صورته (اختياري)' : 'غيّر الصورة',
                        style: AppText.body(11, color: AppColors.neutral700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BoxField(controller: _name, hint: 'اسم اللاعب'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _positions)
                    Pressable(
                      onTap: () => setState(() => _pos = p.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md,
                          color: _pos == p.$1 ? AppColors.accent : null,
                          border: Border.all(color: _pos == p.$1 ? AppColors.accent : AppColors.line, width: 1.4),
                        ),
                        child: Text(p.$2, style: AppText.h(12, color: _pos == p.$1 ? AppColors.white : AppColors.ink)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: () {
                  final n = _name.text.trim();
                  if (n.isNotEmpty) Navigator.pop(context, (name: n, position: _pos, photo: _photo, photoExt: _ext));
                },
                child: Container(
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text('أضِف', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
