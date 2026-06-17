import '../../../core/models/track.dart';

class MovieWishesService {
  MovieWishesService._();
  static final instance = MovieWishesService._();

  final List<Track> _songs = [];
  List<Track> get songs => List.unmodifiable(_songs);

  void add(Track t) {
    if (!_songs.any((s) => s.id == t.id)) _songs.add(t);
  }

  void remove(Track t) => _songs.removeWhere((s) => s.id == t.id);

  bool contains(Track t) => _songs.any((s) => s.id == t.id);
}
