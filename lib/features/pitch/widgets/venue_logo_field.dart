import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/net_image.dart';
import '../data/venues_repository.dart';

/// لوجو الملعب: دوسة تختار صورة وتترفع — بيظهر على كروت شير الماتشات اللي في الملعب.
class VenueLogoField extends StatefulWidget {
  const VenueLogoField({super.key, required this.userId, required this.url, required this.onChanged});

  final String userId;
  final String? url;
  final ValueChanged<String?> onChanged;

  @override
  State<VenueLogoField> createState() => _VenueLogoFieldState();
}

class _VenueLogoFieldState extends State<VenueLogoField> {
  bool _busy = false;

  Future<void> _pick() async {
    final repo = context.read<VenuesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (f == null) return;
    setState(() => _busy = true);
    try {
      final url = await repo.uploadPhoto(widget.userId, await f.readAsBytes(), f.name.split('.').last);
      widget.onChanged(url);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'تعذّر رفع اللوجو'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    return Row(
      children: [
        GestureDetector(
          onTap: _busy ? null : _pick,
          child: Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.2),
            ),
            child: _busy
                ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2))
                : (url == null
                      ? Icon(Icons.add_photo_alternate_outlined, color: AppColors.neutral600)
                      : NetImage(url, fallback: const Icon(Icons.image_not_supported_outlined))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            url == null ? 'ضيف لوجو الملعب — بيظهر على كروت الشير' : 'دوس على اللوجو تغيّره',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
        ),
        if (url != null)
          IconButton(
            onPressed: () => widget.onChanged(null),
            icon: Icon(Icons.close, color: AppColors.danger),
          ),
      ],
    );
  }
}
