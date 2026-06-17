import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class HindiApiService {
  static const _base = 'https://itunes.apple.com/search';
  static const _queries = [
    'arijit singh', 'shreya ghoshal', 'sonu nigam', 'kumar sanu',
    'kishore kumar', 'lata mangeshkar', 'Mohammed Rafi', 'Asha Bhosle',
    'udit narayan', 'atif aslam', 'neha kakkar', 'armaan malik',
    'jubin nautiyal', 'bollywood hits 2024', 'hindi romantic songs',
    'darshan raval', 'B Praak', 'Vishal Mishra', 'Pritam hindi',
    'hindi sad songs',
  ];
  static const _limit = 50;
  int _pointer = 0;
  final Map<String, int> _offsets = {};
  final Map<String, bool> _exhausted = {};
  final Set<int> _seenIds = {};

  bool get hasMore => _pointer < _queries.length;

  Future<List<Track>> fetchNextPage() async {
    final futures = <Future<List<Track>>>[];
    int count = 0;
    int i = _pointer;
    while (i < _queries.length && count < 3) {
      final q = _queries[i];
      if (!(_exhausted[q] ?? false)) {
        futures.add(_fetch(q));
        count++;
      }
      i++;
    }
    _pointer = i;
    if (futures.isEmpty) return [];
    final results = await Future.wait(futures);
    return results.expand((t) => t).toList();
  }

  Future<List<Track>> _fetch(String query) async {
    final offset = _offsets[query] ?? 0;
    final q = Uri.encodeComponent(query);
    final uri = Uri.parse(
        '$_base?term=$q&country=IN&media=music&entity=song&limit=$_limit&offset=$offset');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) { _exhausted[query] = true; return []; }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>?) ?? [];
      final tracks = list
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .where((t) => t.preview != null && _seenIds.add(t.id))
          .toList();
      if (list.length < _limit) { _exhausted[query] = true; }
      else { _offsets[query] = offset + _limit; }
      return tracks;
    } catch (_) { _exhausted[query] = true; return []; }
  }

  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final results = await Future.wait([
      _searchSingle(query, 30),
      _searchSingle('$query hindi', 20),
    ]);
    final seen = <int>{};
    return results.expand((t) => t).where((t) => seen.add(t.id)).toList();
  }

  Future<List<Track>> _searchSingle(String query, int limit) async {
    final q = Uri.encodeComponent(query);
    final uri = Uri.parse('$_base?term=$q&country=IN&media=music&entity=song&limit=$limit');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>?) ?? [];
      return list.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .where((t) => t.preview != null).toList();
    } catch (_) { return []; }
  }

  void reset() { _pointer = 0; _offsets.clear(); _exhausted.clear(); _seenIds.clear(); }
}

class MarathiApiService {
  static const _base = 'https://itunes.apple.com/search';
  static const _queries = [
    'ajay atul', 'swapnil bandodkar', 'bela shende', 'vaibhav joshi',
    'rohit raut', 'sairat marathi', 'natrang marathi', 'marathi lokgeet',
    'shankar mahadevan marathi', 'suresh wadkar', 'avadhoot gupte',
    'mahesh kale', 'marathi superhit', 'marathi natak songs',
    'me shivajiraje', 'anand shinde', 'vitthal umap', 'milind shinde',
    'adarsh shinde', 'marathi lavani',
  ];
  static const _limit = 50;
  int _pointer = 0;
  final Map<String, int> _offsets = {};
  final Map<String, bool> _exhausted = {};
  final Set<int> _seenIds = {};

  bool get hasMore => _pointer < _queries.length;

  Future<List<Track>> fetchNextPage() async {
    final futures = <Future<List<Track>>>[];
    int count = 0;
    int i = _pointer;
    while (i < _queries.length && count < 3) {
      final q = _queries[i];
      if (!(_exhausted[q] ?? false)) {
        futures.add(_fetch(q));
        count++;
      }
      i++;
    }
    _pointer = i;
    if (futures.isEmpty) return [];
    final results = await Future.wait(futures);
    return results.expand((t) => t).toList();
  }

  Future<List<Track>> _fetch(String query) async {
    final offset = _offsets[query] ?? 0;
    final q = Uri.encodeComponent(query);
    final uri = Uri.parse(
        '$_base?term=$q&country=IN&media=music&entity=song&limit=$_limit&offset=$offset');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) { _exhausted[query] = true; return []; }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>?) ?? [];
      final tracks = list
          .map((e) => Track.fromJson(e as Map<String, dynamic>))
          .where((t) => t.preview != null && _seenIds.add(t.id))
          .toList();
      if (list.length < _limit) { _exhausted[query] = true; }
      else { _offsets[query] = offset + _limit; }
      return tracks;
    } catch (_) { _exhausted[query] = true; return []; }
  }

  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final results = await Future.wait([
      _searchSingle('$query marathi', 30),
      _searchSingle(query, 20),
    ]);
    final seen = <int>{};
    return results.expand((t) => t).where((t) => seen.add(t.id)).toList();
  }

  Future<List<Track>> _searchSingle(String query, int limit) async {
    final q = Uri.encodeComponent(query);
    final uri = Uri.parse('$_base?term=$q&country=IN&media=music&entity=song&limit=$limit');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>?) ?? [];
      return list.map((e) => Track.fromJson(e as Map<String, dynamic>))
          .where((t) => t.preview != null).toList();
    } catch (_) { return []; }
  }

  void reset() { _pointer = 0; _offsets.clear(); _exhausted.clear(); _seenIds.clear(); }
}
