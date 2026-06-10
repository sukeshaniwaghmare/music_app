abstract class TrackDetailEvent {}

class TrackDetailFetch extends TrackDetailEvent {
  TrackDetailFetch(this.trackId);
  final int trackId;
}
