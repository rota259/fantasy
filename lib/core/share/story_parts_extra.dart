part of 'story_parts.dart';

/// خانة رقم/اسم جوه الكارت: تسمية صغيرة فوق + القيمة + سطر تحتها.
class StoryTile extends StatelessWidget {
  const StoryTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.accent = StoryColors.lime,
    this.big = false,
  });

  final String label, value;
  final String? sub;
  final Color accent;
  final bool big; // القيمة رقم كبير في النص (مش اسم)

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: big ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (big)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppText.h(26, color: accent)),
          ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: AppText.kicker(color: big ? Colors.white70 : accent, size: 10)),
        ),
        if (!big) ...[
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.h(15, color: Colors.white),
          ),
        ],
        if (sub != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(sub!, style: AppText.h(13, color: accent)),
          ),
      ],
    ),
  );
}
