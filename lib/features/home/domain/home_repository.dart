import '../../../core/models/track.dart';
import '../../../core/services/supabase_service.dart';

class HomeRepository {
  final _supabase = SupabaseService();

  Future<List<Track>> fetchOldSongs() => _supabase.fetchSongs(limit: 20, category: 'old_song');
  Future<List<Track>> fetchEnglishSongs() => _supabase.fetchSongs(limit: 20, category: 'english');
  Future<List<Track>> fetchMovieSongs(String folderName) => _supabase.fetchSongsFromFolder(folderName);
}
