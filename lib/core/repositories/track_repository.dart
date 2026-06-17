import '../models/track.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/supabase_service.dart';

/// Paging strategy:
/// We cycle through queries 'a'-'z' then '0'-'9' (36 chars).
/// Each query supports up to 1000 results via index paging (50 per page → 20 pages).
/// 36 × 1000 = 36,000 theoretical max from Deezer; in practice we page until
/// the API returns fewer than [limit] items (exhausted).
class TrackRepository {
  TrackRepository({ApiService? api, ConnectivityService? connectivity, bool useSupabase = true})
      : _api = api ?? ApiService(),
        _connectivity = connectivity ?? ConnectivityService(),
        _supabase = SupabaseService(),
        _useSupabase = useSupabase;

  final ApiService _api;
  final ConnectivityService _connectivity;
  final SupabaseService _supabase;
  final bool _useSupabase;

  int _supabaseOffset = 0;
  bool _supabaseExhausted = false;

  static const _queries = [
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9',
  ];

  // Paging state per query
  final Map<String, int> _queryIndex = {};
  final Map<String, bool> _queryExhausted = {};
  int _queryPointer = 0;

  bool get hasMore => _useSupabase
      ? !_supabaseExhausted
      : _queryPointer < _queries.length || _queries.any((q) => !(_queryExhausted[q] ?? false));

  void reset() {
    _queryIndex.clear();
    _queryExhausted.clear();
    _queryPointer = 0;
    _supabaseOffset = 0;
    _supabaseExhausted = false;
  }

  Future<List<Track>> fetchNextPage() async {
    if (!(await _connectivity.isConnected())) {
      throw const NoInternetException();
    }

    if (_useSupabase) {
      if (_supabaseExhausted) return [];
      const limit = 50;
      final tracks = await _supabase.fetchSongs(offset: _supabaseOffset, limit: limit);
      _supabaseOffset += tracks.length;
      if (tracks.length < limit) _supabaseExhausted = true;
      return tracks;
    }

    // iTunes fallback
    while (_queryPointer < _queries.length) {
      final q = _queries[_queryPointer];
      if (!(_queryExhausted[q] ?? false)) break;
      _queryPointer++;
    }
    if (_queryPointer >= _queries.length) return [];

    final q = _queries[_queryPointer];
    final idx = _queryIndex[q] ?? 0;
    const limit = 50;

    final tracks = await _api.fetchTracks(query: q, index: idx, limit: limit);
    _queryIndex[q] = idx + tracks.length;

    if (tracks.isEmpty) {
      _queryExhausted[q] = true;
      _queryPointer++;
    }

    return tracks;
  }

  Future<Track?> fetchTrackDetail(int id) async {
    if (!(await _connectivity.isConnected())) {
      throw const NoInternetException();
    }
    return _api.fetchTrackDetail(id);
  }
}

class NoInternetException implements Exception {
  const NoInternetException();
  @override
  String toString() => 'NO INTERNET CONNECTION';
}
