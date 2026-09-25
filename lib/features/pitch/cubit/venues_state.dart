part of 'venues_cubit.dart';

enum VenuesStatus { initial, loading, loaded }

class VenuesState extends Equatable {
  const VenuesState({this.status = VenuesStatus.initial, this.venues = const [], this.ratings = const {}});

  final VenuesStatus status;
  final List<Venue> venues;
  final Map<String, ({double avg, int count})> ratings; // venueId → التقييم

  bool get isLoading => status == VenuesStatus.loading;
  bool get hasData => venues.isNotEmpty;

  @override
  List<Object?> get props => [status, venues, ratings];
}
