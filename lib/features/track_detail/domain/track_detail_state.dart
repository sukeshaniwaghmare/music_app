import '../../../core/models/track.dart';

enum TrackDetailStatus { initial, loading, success, failure }

class TrackDetailState {
  const TrackDetailState({
    this.status = TrackDetailStatus.initial,
    this.track,
    this.error,
  });

  final TrackDetailStatus status;
  final Track? track;
  final String? error;

  TrackDetailState copyWith({
    TrackDetailStatus? status,
    Track? track,
    String? error,
  }) {
    return TrackDetailState(
      status: status ?? this.status,
      track: track ?? this.track,
      error: error,
    );
  }
}
