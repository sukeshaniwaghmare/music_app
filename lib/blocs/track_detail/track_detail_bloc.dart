import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/track_repository.dart';
import 'track_detail_event.dart';
import 'track_detail_state.dart';

class TrackDetailBloc extends Bloc<TrackDetailEvent, TrackDetailState> {
  TrackDetailBloc({TrackRepository? repository})
      : _repo = repository ?? TrackRepository(),
        super(const TrackDetailState()) {
    on<TrackDetailFetch>(_onFetch);
  }

  final TrackRepository _repo;

  Future<void> _onFetch(
    TrackDetailFetch event,
    Emitter<TrackDetailState> emit,
  ) async {
    emit(state.copyWith(status: TrackDetailStatus.loading));
    try {
      final track = await _repo.fetchTrackDetail(event.trackId);
      if (track == null) {
        emit(state.copyWith(
          status: TrackDetailStatus.failure,
          error: 'Track not found',
        ));
      } else {
        emit(state.copyWith(status: TrackDetailStatus.success, track: track));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TrackDetailStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
