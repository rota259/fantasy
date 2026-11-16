import 'package:flutter/material.dart';
import '../../../core/app_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/widgets/match_format.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../pitch/data/models/venue.dart';
import '../../pitch/data/venues_repository.dart';
import '../data/tournaments_repository.dart';

part 'create_tournament_sheet_parts.dart';

/// بطولة جديدة في ملعب موثّق: الملعب · الاسم · النظام · عدد الفرق (والمجموعات) · البداية · الجايزة والراعي. بيرجّع الـ id.
Future<String?> showCreateTournamentSheet(BuildContext context) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.bg,
  builder: (_) => const _CreateSheet(),
);

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _name = TextEditingController();
  final _prize = TextEditingController();
  final _sponsor = TextEditingController();
  String _format = 'groups';
  int _teams = 8;
  int _groups = 2;
  DateTime _start = DateTime.now().add(const Duration(days: 3));
  bool _busy = false;
  late final Future<List<Venue>> _venues;
  String? _venue;

  void _set(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _venues = _loadVenues();
  }

  @override
  void dispose() {
    _name.dispose();
    _prize.dispose();
    _sponsor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (_venue == null) {
      messenger.showSnackBar(const SnackBar(content: Text('اختار الملعب')));
      return;
    }
    if (_name.text.trim().length < 2) {
      messenger.showSnackBar(const SnackBar(content: Text('اكتب اسم البطولة')));
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await context.read<TournamentsRepository>().create(
        name: _name.text.trim(),
        format: _format,
        teamCount: _teams,
        groups: _format == 'groups' ? _groups : 0,
        startsAt: _start,
        prize: _prize.text,
        sponsor: _sponsor.text,
        venueId: _venue,
      );
      nav.pop(id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget chip(String v, String label) =>
        ChoiceChip(label: Text(label), selected: _format == v, onSelected: (_) => setState(() => _format = v));
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('بطولة جديدة', style: AppText.h(18)),
            const SizedBox(height: 8),
            _venuePicker(),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(hintText: 'اسم البطولة (مثلًا كاس بدر)'),
            ),
            const SizedBox(height: 12),
            Text('النظام', style: AppText.h(13)),
            Wrap(
              spacing: 6,
              children: [
                chip('groups', 'مجموعات + خروج مغلوب'),
                chip('knockout', 'خروج المغلوب'),
                chip('league', 'دوري'),
              ],
            ),
            const SizedBox(height: 8),
            _stepper('عدد الفرق', _teams, 3, 32, (v) => setState(() => _teams = v)),
            if (_format == 'groups')
              _stepper(
                'عدد المجموعات',
                _groups,
                2,
                (_teams / 2).floor().clamp(2, 8),
                (v) => setState(() => _groups = v),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('البداية', style: AppText.h(13)),
              subtitle: Text('${arabicWeekday(_start)} ${_start.day}/${_start.month} · ${arabicTime(_start)}'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            TextField(
              controller: _prize,
              decoration: const InputDecoration(hintText: 'الجايزة (اختياري)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sponsor,
              decoration: const InputDecoration(hintText: 'الراعي (اختياري)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? '...' : 'اعمل البطولة')),
          ],
        ),
      ),
    );
  }
}
