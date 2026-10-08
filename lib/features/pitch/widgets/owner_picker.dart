import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';
import '../../manager/data/admin_repository.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// (أدمن) صاحب الملعب: بحث في السيرفر بالاسم/الموبايل (مش قايمة بكل اليوزرز).
class OwnerPicker extends StatefulWidget {
  const OwnerPicker({super.key, required this.ownerId, required this.onChanged});

  final String? ownerId;
  final ValueChanged<String?> onChanged;

  @override
  State<OwnerPicker> createState() => _OwnerPickerState();
}

class _OwnerPickerState extends State<OwnerPicker> {
  late Future<String?> _name = _nameOf(widget.ownerId);

  static Future<String?> _nameOf(String? id) async {
    if (id == null) return null;
    final row = await SupabaseService.table('profiles').select('name').eq('id', id).maybeSingle();
    return row?['name'] as String?;
  }

  Future<void> _pick() async {
    final picked = await showModalBottomSheet<AppUser?>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.8, child: _Search(repo: context.read<AdminRepository>())),
    );
    if (picked == null || !mounted) return;
    widget.onChanged(picked.id.isEmpty ? null : picked.id);
    setState(() {
      _name = Future.value(picked.id.isEmpty ? null : picked.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: _pick,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: FutureBuilder<String?>(
          future: _name,
          builder: (context, snap) => Row(
            children: [
              Expanded(child: Text(snap.data ?? 'مفيش (الإدارة تأكّد الحجوزات)', style: AppText.body(13))),
              const Icon(Icons.search, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Search extends StatefulWidget {
  const _Search({required this.repo});
  final AdminRepository repo;

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  Future<List<AppUser>>? _results;

  void _search(String q) => setState(() {
    _results = q.trim().length < 2 ? null : widget.repo.fetchUsers(query: q.trim(), limit: 30);
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'اكتب الاسم أو الموبايل ودوس بحث',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          ListTile(
            title: Text('مفيش صاحب (الإدارة تأكّد الحجوزات)', style: AppText.h(13)),
            onTap: () => Navigator.pop(context, const AppUser(id: '', name: '', email: '')),
          ),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _results,
              builder: (context, snap) {
                if (_results == null) return const SizedBox.shrink();
                if (!snap.hasData) return const SkeletonList();
                return ListView(
                  children: [
                    for (final u in snap.data!)
                      ListTile(
                        title: Text(u.name.isEmpty ? u.email : u.name, style: AppText.h(13)),
                        subtitle: Text(u.phone ?? u.email, style: AppText.body(11)),
                        onTap: () => Navigator.pop(context, u),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
