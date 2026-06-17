import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/track.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/saavn_api_service.dart';
import '../../../core/services/audio_player_service.dart';
import '../../favorites/domain/favorites_service.dart';
import '../../recently_played/domain/recently_played_service.dart';
import '../../movie_wishes/domain/movie_wishes_service.dart';
import '../../track_detail/presentation/track_detail_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../queue/presentation/queue_screen.dart';
import '../../recently_played/presentation/recently_played_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../ringtones/presentation/ringtones_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.initialTab = 0, this.filterCategory});
  final int initialTab;
  final String? filterCategory;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  final List<Track> _allSongs = [];
  bool _loading = false;
  bool _loaded = false;

  final _hindiApi = HindiApiService();
  final _marathiApi = MarathiApiService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void didUpdateWidget(LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterCategory != widget.filterCategory) {
      _allSongs.clear();
      _loaded = false;
      _loading = false;
      _loadAll();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final category = widget.filterCategory;
      List<Track> combined = [];
      final seen = <int>{};

      if (category == null || category == 'old_song' || category == 'english') {
        final supabaseSongs = await SupabaseService().fetchSongs(limit: 500, category: category);
        combined.addAll(supabaseSongs);
      }
      if (category == null || category == 'hindi') {
        combined.addAll(await _hindiApi.fetchNextPage());
      }
      if (category == null || category == 'marathi') {
        combined.addAll(await _marathiApi.fetchNextPage());
      }

      if (!mounted) return;
      final result = combined.where((t) => seen.add(t.id)).toList();
      result.sort((a, b) => a.title.compareTo(b.title));
      setState(() {
        _allSongs.addAll(result);
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Track> get _filtered {
    if (_searchQuery.isEmpty) return _allSongs;
    return _allSongs.where((t) =>
        t.title.toLowerCase().contains(_searchQuery) ||
        t.artist.toLowerCase().contains(_searchQuery)).toList();
  }

  String get _categoryTitle {
    switch (widget.filterCategory) {
      case 'old_song': return '🎙️ Old Songs';
      case 'english': return '🎸 English';
      case 'hindi': return '🎵 Hindi';
      case 'marathi': return '🥁 Marathi';
      default: return 'My Library';
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = v.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0D0D14),
            padding: const EdgeInsets.fromLTRB(16, 52, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(_categoryTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_active_rounded,
                        color: Color(0xFFB44FE8), size: 22),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RingtonesScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded,
                        color: Color(0xFFE85D75), size: 22),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded,
                        color: Colors.white54, size: 22),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen())),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white38),
                    color: const Color(0xFF1E1E2E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'queue') Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));
                      if (v == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'queue', child: Row(children: [Icon(Icons.queue_music_rounded, color: Colors.purpleAccent, size: 20), SizedBox(width: 12), Text('Queue', style: TextStyle(color: Colors.white))])),
                      const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_rounded, color: Colors.white54, size: 20), SizedBox(width: 12), Text('Settings', style: TextStyle(color: Colors.white))])),
                    ],
                  ),
                ]),
                if (_loaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 2),
                    child: Text('${_allSongs.length} songs',
                        style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ),
                const SizedBox(height: 10),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C28),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 16),
                              onPressed: () { _searchController.clear(); _onSearch(''); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _loading && _allSongs.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB44FE8)))
                : songs.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.music_off_rounded, color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No songs found',
                            style: const TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 100),
                        itemCount: songs.length,
                        itemBuilder: (context, i) => _LibTile(
                          track: songs[i],
                          allTracks: songs,
                          index: i,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _LibTile extends StatefulWidget {
  const _LibTile({required this.track, required this.allTracks, required this.index});
  final Track track;
  final List<Track> allTracks;
  final int index;
  @override
  State<_LibTile> createState() => _LibTileState();
}

class _LibTileState extends State<_LibTile> {
  final _fav = FavoritesService.instance;
  final _audio = AudioPlayerService.instance;
  final _wishes = MovieWishesService.instance;
  bool _isDownloading = false;

  void _play() {
    RecentlyPlayedService.instance.add(widget.track);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TrackDetailScreen(
          track: widget.track, tracks: widget.allTracks, currentIndex: widget.index),
    ));
  }

  void _showOptions() {
    final isFav = _fav.isFavorite(widget.track.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13131F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 3,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
                child: _Cover(track: widget.track, size: 48)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(widget.track.artist, maxLines: 1,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ])),
          ]),
        ),
        const Divider(color: Colors.white10, height: 1),
        _tile(Icons.play_arrow_rounded, 'Play Now', () { Navigator.pop(context); _play(); }),
        _tile(Icons.queue_music_rounded, 'Add to Queue', () {
          Navigator.pop(context); _audio.addToQueue(widget.track);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to queue'), behavior: SnackBarBehavior.floating));
        }),
        _tile(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          isFav ? 'Remove from Favorites' : 'Add to Favorites',
          () { Navigator.pop(context); _fav.toggle(widget.track); setState(() {}); },
          color: isFav ? Colors.red : Colors.white70,
        ),
        StatefulBuilder(
          builder: (ctx, setLocal) {
            final inWishes = _wishes.contains(widget.track);
            return _tile(
              Icons.movie_filter_rounded,
              inWishes ? 'Remove from Movie Wishes' : 'Add to Movie Wishes',
              () {
                if (inWishes) { _wishes.remove(widget.track); } else { _wishes.add(widget.track); }
                setLocal(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(inWishes ? 'Removed from Movie Wishes' : 'Added to Movie Wishes 🎥'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF7C3AED),
                ));
              },
              color: inWishes ? const Color(0xFFB44FE8) : Colors.white70,
            );
          },
        ),
        if (widget.track.preview != null)
          _tile(Icons.download_rounded, 'Download', () { Navigator.pop(context); _download(); }),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white70}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      onTap: onTap,
    );
  }

  Future<void> _download() async {
    if (widget.track.preview == null) return;
    setState(() => _isDownloading = true);
    try {
      final dir = Platform.isAndroid ? Directory('/storage/emulated/0/Music') : await getApplicationDocumentsDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      final name = '${widget.track.title.replaceAll(RegExp(r'[^\w\s]'), '').trim()}.m4a';
      await Dio().download(widget.track.preview!, '${dir.path}/$name');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded: $name'), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF7C3AED)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _audio.currentTrack?.id == widget.track.id;
    return InkWell(
      onTap: _play,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
          color: isPlaying ? const Color(0xFF1C1030) : Colors.transparent,
        ),
        child: Row(children: [
          SizedBox(width: 28,
            child: Text('${widget.index + 1}',
                style: TextStyle(
                    color: isPlaying ? const Color(0xFFB44FE8) : Colors.white24,
                    fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8),
              child: _Cover(track: widget.track, size: 48)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isPlaying ? const Color(0xFFB44FE8) : Colors.white,
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(widget.track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
          ])),
          if (isPlaying)
            const Padding(padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.graphic_eq_rounded, color: Color(0xFFB44FE8), size: 18))
          else
            IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
                onPressed: _showOptions, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
      ),
    );
  }
}

class _Cover extends StatefulWidget {
  const _Cover({required this.track, required this.size});
  final Track track;
  final double size;
  @override
  State<_Cover> createState() => _CoverState();
}

class _CoverState extends State<_Cover> {
  String? _url;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.track.albumCover != null) { _url = widget.track.albumCover; _loading = false; }
    else _fetch();
  }

  Future<void> _fetch() async {
    try {
      final q = Uri.encodeComponent('${widget.track.title} ${widget.track.artist}');
      final res = await http.get(Uri.parse('https://itunes.apple.com/search?term=$q&entity=song&limit=1'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body)['results'] as List?) ?? [];
        if (list.isNotEmpty) {
          final url = (list.first['artworkUrl100'] as String?)?.replaceAll('100x100bb', '300x300bb');
          if (mounted) setState(() { _url = url; _loading = false; });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    if (_loading) return Container(width: s, height: s, color: const Color(0xFF1C1C28),
        child: const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24))));
    if (_url != null) return Image.network(_url!, width: s, height: s, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph(s));
    return _ph(s);
  }

  Widget _ph(double s) => Container(width: s, height: s,
    color: const Color(0xFF1C1C28),
    child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 18));
}
