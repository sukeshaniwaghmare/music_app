import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class ApiService {
  static const _base = 'https://itunes.apple.com';

  Future<List<Track>> fetchTracks({
    required String query,
    required int index,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$_base/search?term=$query&offset=$index&limit=$limit&entity=song');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['results'] as List<dynamic>? ?? [];
    return list.map((e) => Track.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Track?> fetchTrackDetail(int trackId) async {
    final uri = Uri.parse('$_base/lookup?id=$trackId&entity=song');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['results'] as List<dynamic>? ?? [];
    if (list.isEmpty) return null;
    return Track.fromJson(list.first as Map<String, dynamic>);
  }
}
