import '../models/track.dart';

class FavoritesService {
  FavoritesService._();
  static final instance = FavoritesService._();

  final List<Track> _favorites = [];

  List<Track> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(int id) => _favorites.any((t) => t.id == id);

  void toggle(Track track) {
    if (isFavorite(track.id)) {
      _favorites.removeWhere((t) => t.id == track.id);
    } else {
      _favorites.add(track);
    }
  }
}
