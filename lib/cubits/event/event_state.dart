part of 'event_cubit.dart';

abstract class EventState extends Equatable {
  const EventState();
  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<EventModel> events;
  const EventLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class EventAdded extends EventState {}

class EventDeleted extends EventState {}

class EventError extends EventState {
  final String error;
  const EventError(this.error);

  @override
  List<Object?> get props => [error];
}
