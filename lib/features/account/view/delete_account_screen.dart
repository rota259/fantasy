import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../../core/widgets/motion.dart';

/// حذف الحساب نهائيًا (Apple و Google بيطلبوه): بيكتب "امسح" عشان يأكّد.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const _word = 'امسح';
  final _confirm = TextEditingController();
  bool _busy = false;

  static const _gone = [
    'بروفايلك وصورتك واسمك ورقمك وإيميلك',
    'تشكيلاتك ونقطك وشاراتك وترتيبك في كل الدوريات',
    'توقعاتك وتصويتاتك وتقييماتك وحجوزاتك',
    'الدوريات اللي انت عاملها بتفضل من غير صاحب، والملاعب اللي ضايفها بتفضل من غير صاحب',
  ];

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    final err = await context.read<AuthCubit>().deleteAccount();
    if (err == null) {
      nav.popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(content: Text('اتمسح حسابك وكل بياناتك ✓')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _confirm.text.trim() == _word && !_busy;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'امسح حسابي', subtitle: 'DELETE ACCOUNT', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('الحذف نهائي ومفيش رجوع فيه.', style: AppText.h(16, color: AppColors.danger)),
                const SizedBox(height: 12),
                Text('هيتمسح:', style: AppText.h(13)),
                for (final g in _gone)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('• $g', style: AppText.body(13)),
                  ),
                const SizedBox(height: 20),
                Text('اكتب «$_word» عشان تأكّد', style: AppText.h(13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirm,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 16),
                Pressable(
                  onTap: ready ? _delete : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ready ? AppColors.danger : AppColors.neutral400,
                      borderRadius: AppRadius.md,
                    ),
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.center,
                    child: Text(_busy ? 'بيتمسح…' : 'امسح حسابي نهائيًا', style: AppText.h(15, color: AppColors.white)),
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
