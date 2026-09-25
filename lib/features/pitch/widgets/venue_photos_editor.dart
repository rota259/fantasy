import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/venues_repository.dart';
import '../../../core/widgets/net_image.dart';

/// صور الملعب: إضافة من المعرض (بترتفع على Storage في فولدر صاحبها) + حذف.
class VenuePhotosEditor extends StatefulWidget {
  const VenuePhotosEditor({super.key, required this.userId, required this.photos, required this.onChanged});

  final String userId;
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  @override
  State<VenuePhotosEditor> createState() => _VenuePhotosEditorState();
}

class _VenuePhotosEditorState extends State<VenuePhotosEditor> {
  bool _uploading = false;

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<VenuesRepository>();
    final files = await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1280);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    final urls = [...widget.photos];
    var failed = 0;
    for (final f in files) {
      try {
        final ext = f.name.contains('.') ? f.name.split('.').last : 'jpg';
        urls.add(await repo.uploadPhoto(widget.userId, await f.readAsBytes(), ext));
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() => _uploading = false);
    widget.onChanged(urls);
    if (failed > 0) {
      messenger.showSnackBar(SnackBar(content: Text('$failed صورة مترفعتش — جرّب تاني')));
    }
  }

  void _remove(String url) => widget.onChanged([...widget.photos]..remove(url));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _uploading ? null : _add,
            child: Container(
              width: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
              child: _uploading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.accent),
                        const SizedBox(height: 4),
                        Text('ضيف صور', style: AppText.h(11)),
                      ],
                    ),
            ),
          ),
          for (final url in widget.photos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  NetImage(
                    url,
                    width: 96,
                    height: 96,
                    fallback: Container(
                      width: 96,
                      height: 96,
                      color: AppColors.neutral200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: GestureDetector(
                      onTap: () => _remove(url),
                      child: Container(
                        color: AppColors.black,
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, size: 16, color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
