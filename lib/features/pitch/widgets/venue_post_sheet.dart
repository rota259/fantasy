import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// (صاحب الملعب) إعلان لأهل المنطقة: تعديل عادي أو تجديد (التقييم بيبدأ من الأول). بيرجّع (النوع، الكلام).
Future<(String, String)?> showVenuePostSheet(BuildContext context) => showModalBottomSheet<(String, String)>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.bg,
  builder: (_) => const _PostSheet(),
);

class _PostSheet extends StatefulWidget {
  const _PostSheet();

  @override
  State<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<_PostSheet> {
  final _body = TextEditingController();
  String _kind = 'update';

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _send() {
    final b = _body.text.trim();
    if (b.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الجديد في الملعب')));
      return;
    }
    Navigator.pop(context, (_kind, b));
  }

  @override
  Widget build(BuildContext context) {
    final reno = _kind == 'renovation';
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('📣 أعلن لأهل منطقتك', style: AppText.h(18)),
          const SizedBox(height: 4),
          Text(
            'كل اليوزرز في المنطقة هيوصلهم إشعار — إعلان واحد كل ٢٤ ساعة.',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              ChoiceChip(
                label: const Text('تعديل / عرض'),
                selected: !reno,
                onSelected: (_) => setState(() => _kind = 'update'),
              ),
              ChoiceChip(
                label: const Text('تجديد الملعب'),
                selected: reno,
                onSelected: (_) => setState(() => _kind = 'renovation'),
              ),
            ],
          ),
          if (reno)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'التجديد بيبدأ التقييم من الأول: التقييمات القديمة بتفضل ظاهرة بس مبتدخلش في المتوسط، '
                'والناس بيوصلها «جرّبه وقيّمه من جديد». مرة كل ٣٠ يوم.',
                style: AppText.body(11, color: AppColors.accent700),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: reno ? 'مثلًا: نجيلة جديدة وإضاءة LED' : 'مثلًا: خصم ٢٠٪ على مواعيد الصبح',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _send, child: const Text('ابعت الإعلان')),
        ],
      ),
    );
  }
}
