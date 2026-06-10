import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class SaavnApiService {
  static const _base = 'https://itunes.apple.com/search';

  static const _queries = [
    'ajay atul',
    'aadhe rahude',
    'arijit singh',
    'shreya ghoshal marathi',
    'sonu nigam hindi',
    'kumar sanu',
    'lata mangeshkar',
    'kishore kumar',
    'udit narayan',
    'marathi superhit',
    'bollywood hits',
  ];

  int _queryPointer = 0;
  int _offsetPointer = 0;
  static const _limit = 50;
  final Set<int> _seenIds = {};

  bool get hasMore => _queryPointer < _queries.length;

  Future<List<Track>> fetchNextPage() async {
    if (_queryPointer >= _queries.length) return [];

    final query = Uri.encodeComponent(_queries[_queryPointer]);
    final uri = Uri.parse(
        '$_base?term=$query&country=IN&media=music&entity=song&limit=$_limit&offset=$_offsetPointer');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?) ?? [];
    final List<Track> tracks = results
        .map((e) => Track.fromJson(e as Map<String, dynamic>))
        .where((t) => t.preview != null && _seenIds.add(t.id))
        .toList();

    if (tracks.length < _limit) {
      _queryPointer++;
      _offsetPointer = 0;
    } else {
      _offsetPointer += _limit;
    }

    return tracks;
  }

  void reset() {
    _queryPointer = 0;
    _offsetPointer = 0;
    _seenIds.clear();
  }
}
