import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/integrity_repository.dart';
import '../data/models/organizer_request.dart';
import '../widgets/note_dialog.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// "عايز أنظّم ماتشات": القواعد + طلب للأدمن + حالة الطلب.
class OrganizerRequestScreen extends StatefulWidget {
  const OrganizerRequestScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OrganizerRequestScreen> createState() => _OrganizerRequestScreenState();
}

class _OrganizerRequestScreenState extends State<OrganizerRequestScreen> {
  late final IntegrityRepository _repo = context.read<IntegrityRepository>();
  late Future<OrganizerRequest?> _future = _repo.myOrganizerRequest(widget.userId);

  static const _rules = [
    'بتعمل ماتشاتك وتنزّل التشكيلة وتسجّل الأهداف والأسيستات.',
    'مينفعش تختار في الفانتازي أي لاعب من ماتش انت مديره.',
    'بعد الماتش، لاعيبة الفريقين يأكدوا الورقة — ولو حد اعترض الإدارة بتحكم.',
    'أي غش بيتثبت: الماتش بيتلغى ونقطه بتروح والتنظيم بيتسحب.',
  ];

  Future<void> _request() async {
    final note = await showNoteDialog(
      context,
      title: 'قدّم طلب',
      hint: 'بتنظّم ماتشات فين؟ ومين الفرق؟ (اختياري)',
      required: false,
    );
    if (note == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.requestOrganizer(widget.userId, note);
      messenger.showSnackBar(const SnackBar(content: Text('طلبك وصل للإدارة ✓')));
      setState(() {
        _future = _repo.myOrganizerRequest(widget.userId);
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'مدير منطقة', subtitle: 'ORGANIZER', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<OrganizerRequest?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SkeletonList();
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('مدير الماتشات هو اللي بيجمّع الفريقين ويدير الماتش في الأبلكيشن.', style: AppText.h(14)),
                    const SizedBox(height: 12),
                    for (final r in _rules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $r', style: AppText.body(13)),
                      ),
                    const SizedBox(height: 16),
                    _status(snap.data),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(OrganizerRequest? r) {
    if (r != null && r.isPending) {
      return _box('طلبك مستني موافقة الإدارة ⏳', AppColors.bronze);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r?.status == 'rejected') ...[
          _box('طلبك اللي فات اترفض — تقدر تقدّم تاني', AppColors.neutral600),
          const SizedBox(height: 8),
        ],
        Pressable(onTap: _request, child: _box('قدّم طلب للإدارة', AppColors.accent)),
      ],
    );
  }

  Widget _box(String text, Color color) => Container(
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.md),
    padding: const EdgeInsets.all(14),
    alignment: Alignment.center,
    child: Text(text, style: AppText.h(14, color: AppColors.white)),
  );
}
