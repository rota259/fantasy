import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// مشاركة كارت (صورة من أي widget ملفوف في RepaintBoundary بالـ key ده) + نص.
abstract final class ShareCard {
  ShareCard._();

  static Future<void> share(GlobalKey key, String text) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no boundary');
      // عرض الصورة ١٠٨٠ (مقاس الستوري) مهما كان مقاس المعاينة على الشاشة
      final image = await boundary.toImage(pixelRatio: (1080 / boundary.size.width).clamp(2.0, 5.0));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no bytes');
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'khomasi.png')],
        ),
      );
    } catch (_) {
      // لو الصورة فشلت نشارك النص لوحده
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  static Future<void> text(String text) => SharePlus.instance.share(ShareParams(text: text));
}
