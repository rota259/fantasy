import 'package:flutter/material.dart';
import 'organizer_awards_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../../core/zone/zone_scope.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../events/data/events_repository.dart';
import '../../manager/data/lineup_repository.dart';
import '../../manager/view/manager_challenge_screen.dart';
import '../../manager/view/manager_matches_screen.dart';
import '../../matches/data/matches_repository.dart';
import '../../overlays/view/pitch_overlay.dart';
import '../../players/data/players_repository.dart';
import '../../week/data/week_window.dart';
import '../../zones/data/zone.dart';
import '../../zones/data/zones_repository.dart';
import '../../../core/widgets/motion.dart';
import '../../tournaments/view/tournaments_screen.dart';
import '../widgets/captain_reviews.dart';
import '../widgets/trust_card.dart';

part 'organizer_home_screen_sections.dart';

/// رئيسية مدير المنطقة: ماتشاته وفرقه + مواعيد الجولة. (حساب شغل — مفيش فانتازي)
class OrganizerHomeScreen extends StatelessWidget {
  const OrganizerHomeScreen({super.key});

  static const _steps = [
    'الفرق واللاعيبة وصورهم شغل الكباتن — كل كابتن بيعمل فريقه من «فريقي (أنا الكابتن)».',
    'اعمل الماتش قبل ميعاده بساعتين على الأقل — بين فريقين ليهم كباتن في منطقتك، وحط الملعب.',
    'الكباتن بيوصلهم إشعار ويبعتولك التشكيلة. من تاب التشكيلة «طبّقها»، ولو حد اتأخر «فكّره».',
    'لاعيبة الماتش بيتقفلوا في تشكيلات الناس قبله بساعة — فابعت إشعار «التشكيلة نزلت» بدري.',
    'اختار ماتش من ماتشاتك تحدّي للجولة — يوزرز منطقتك يتوقّعوا فرق الأهداف.',
    'وقت الماتش سجّل الأهداف والأسيستات، وفي الآخر اكتب النتيجة واقفله.',
    'الكابتنين (وصاحب الملعب لو موجود) يأكّدوا النتيجة = اعتماد فوري. بعد ٥ ماتشات معتمدة ومن غير إنذارات، ماتشك بيتعتمد لوحده بعد ٤ ساعات.',
    'كل لاعب نقطه في الماتش لحد ٢٥ (والأهداف بعد الخامس مبتتحسبش). كل ماتش الإدارة تلغيه = إنذار، والتالت = إيقاف.',
  ];

  void _push(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
