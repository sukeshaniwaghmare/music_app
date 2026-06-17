import '../../../core/models/track.dart';

class RecentlyPlayedService {
  RecentlyPlayedService._();
  static final instance = RecentlyPlayedService._();

  final List<Track> _tracks = [];
  List<Track> get tracks => List.unmodifiable(_tracks);

  void add(Track track) {
    _tracks.removeWhere((t) => t.id == track.id);
    _tracks.insert(0, track);
    if (_tracks.length > 50) _tracks.removeLast();
  }
}
