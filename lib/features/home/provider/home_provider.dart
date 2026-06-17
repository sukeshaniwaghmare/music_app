import 'package:flutter/foundation.dart';
import '../../../core/models/track.dart';
import '../domain/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  final _repo = HomeRepository();

  List<Track> oldSongs = [];
  List<Track> englishSongs = [];
  bool loading = false;

  Future<void> loadAll() async {
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([_repo.fetchOldSongs(), _repo.fetchEnglishSongs()]);
      oldSongs = results[0];
      englishSongs = results[1];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<Track>> loadMovieSongs(String folderName) => _repo.fetchMovieSongs(folderName);
}
