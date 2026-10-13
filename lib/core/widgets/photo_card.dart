import 'package:flutter/material.dart';

import 'fx/gold_shine.dart';
import 'net_image.dart';

/// صورة لاعب في إطار «كارت» (مش دايرة): مستطيل طولي بحواف ناعمة — فوق مدوّر أكتر زي كروت اللاعيبة —
/// وإطار بلون دوره، وتدريج غامق خفيف تحت عشان الصورة تبان واقفة على الأرض.
///   [gold] = إطار دهب معدني بيلمع (الكابتن وتشكيلة الجولة) · غير كده [frame] لون الإطار.
///   [ornate] = الإطار الكبير بتاع كشف تشكيلة الجولة: دهب + خط داخلي غامق + لمعة أهدى.
class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.url,
    required this.fallback,
    this.width = 46,
    this.frame = Colors.white,
    this.gold = false,
    this.ornate = false,
    this.phase = 0,
  });

  final String url;
  final Widget fallback; // لو الصورة ماحمّلتش
  final double width;
  final Color frame;
  final bool gold, ornate;
  final double phase; // توقيت اللمعة

  double get height => width * 1.24;

  @override
  Widget build(BuildContext context) {
    final w = width, h = height;
    final ring = ornate ? (w * 0.05).clamp(4.0, 7.0) : (w * 0.07).clamp(2.5, 4.5);
    BorderRadius shape(double inset) => BorderRadius.vertical(
      top: Radius.circular((w * 0.30 - inset).clamp(2.0, 100.0)),
      bottom: Radius.circular((w * 0.16 - inset).clamp(2.0, 100.0)),
    );
    final iw = w - ring * 2 - (ornate ? 4 : 0), ih = h - ring * 2 - (ornate ? 4 : 0);
    Widget photo = ClipRRect(
      borderRadius: shape(ring + (ornate ? 2 : 0)),
      child: Stack(
        children: [
          NetImage(
            url,
            width: iw,
            height: ih,
            fallback: SizedBox(
              width: iw,
              height: ih,
              child: Center(child: fallback),
            ),
          ),
          // تدريج غامق خفيف تحت
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: ornate ? 0.38 : 0.22),
                  ],
                  stops: const [0.62, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (ornate) {
      // خط داخلي غامق بين الدهب والصورة
      photo = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: const Color(0xFF5A3D05), borderRadius: shape(ring)),
        child: photo,
      );
    }
    final outer = shape(0);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: outer,
        boxShadow: [
          BoxShadow(color: const Color(0x66000000), blurRadius: ornate ? 16 : 8, offset: Offset(0, ornate ? 6 : 3)),
        ],
      ),
      child: gold || ornate
          ? GoldShine(
              shape: RoundedRectangleBorder(borderRadius: outer),
              padding: EdgeInsets.all(ring),
              delay: phase,
              child: photo,
            )
          : Container(
              padding: EdgeInsets.all(ring),
              decoration: BoxDecoration(color: frame, borderRadius: outer),
              child: photo,
            ),
    );
  }
}
