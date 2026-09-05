part of 'live_feed_cubit.dart';

class LiveFeedState extends Equatable {
  const LiveFeedState({
    required this.count,
    required this.points,
    this.events = const [],
  });

  final int count; // عدد الصفوف المكشوفة
  final int points; // نقاط الجولة الحالية
  final List<FeedEvent> events; // صفوف البث

  @override
  List<Object?> get props => [count, points, events];
}
