import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/event_model.dart';
import 'package:fantasy_5omasi/repositories/event_repository.dart';

part 'event_state.dart';

class EventCubit extends Cubit<EventState> {
  final EventRepository eventRepository;

  EventCubit(this.eventRepository) : super(EventInitial());

  Future<void> fetchEventsByMatch(String matchId) async {
    emit(EventLoading());
    try {
      final events = await eventRepository.getEventsByMatch(matchId);
      emit(EventLoaded(events));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> fetchEventsByPlayer(String playerId) async {
    emit(EventLoading());
    try {
      final events = await eventRepository.getEventsByPlayer(playerId);
      emit(EventLoaded(events));
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> addEvent(EventModel event) async {
    emit(EventLoading());
    try {
      await eventRepository.addEvent(event);
      emit(EventAdded());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> addEvents(List<EventModel> events) async {
    emit(EventLoading());
    try {
      await eventRepository.addEvents(events);
      emit(EventAdded());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }

  Future<void> deleteEvent(String eventId) async {
    emit(EventLoading());
    try {
      await eventRepository.deleteEvent(eventId);
      emit(EventDeleted());
    } catch (e) {
      emit(EventError(e.toString()));
    }
  }
}
