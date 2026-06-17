import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../services/supabase_service.dart';
import '../services/recently_played_service.dart';
import '../services/movie_wishes_service.dart';
import 'track_detail_screen.dart';
import 'favorites_screen.dart';
import 'recently_played_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onGoToLibrary});
  final void Function(String? category) onGoToLibrary;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = SupabaseService();

  List<Track> _oldSongs = [];
  List<Track> _englishSongs = [];
  bool _loading = true;
  bool _movieWishesExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _supabase.fetchSongs(limit: 20, category: 'old_song'),
        _supabase.fetchSongs(limit: 20, category: 'english'),
      ]);
      if (mounted) {
        setState(() {
          _oldSongs = results[0];
          _englishSongs = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _movieFolders = {
    'Anadi':                'Anadi',
    'Andaaz':               'Andaaz',
    'Beta':                 'Beta',
    'Betaab':               'Betaab',
    'Betab':                'Betab',
    'Bol Radha Bol':        'Bol Radha Bol',
    'Dil To Pagal Hai':     'Dil To Pagal Hai',
    'English Song':         'English Song',
    'His Madhuri':          'His Madhuri',
    'Hum Saath Saath Hain': 'Hum Saath Saath Hain',
    'Kaho Na Pyaar Hai':    'Kaho Na Pyaar Hai',
    'Kumar Alka':           'Kumar Alka',
    'Kumar Sanu VOL1':      'Kumar Sanu VOL1',
    'Lavni':                'Lavni',
    'Mara Nisrg Raja':      'Mara Nisrg Raja',
    'Mohabbatein':          'Mohabbatein',
    'Old Song':             'old song',
    'Pardesh':              'Pardesh',
    'Ram Lakhan':           'Ram Lakhan',
    'Ram Teri Ganga Maili': 'Ram Teri Ganga Maili',
  };

  void _goToLibrary(int tabIndex) {
    const categories = {0: 'english', 1: 'hindi', 2: 'marathi', 3: 'old_song'};
    widget.onGoToLibrary(categories[tabIndex]);
  }

  void _openMovieSongs(String movieName) {
    final folder = _movieFolders[movieName];
    if (folder == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13131F),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MovieSongsSheet(movieName: movieName, folderName: folder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: const Color(0xFFB44FE8),
        backgroundColor: const Color(0xFF1E1E2E),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFFB44FE8))),
              )
            else ...[
              _sectionHeader('🎙️ Old Songs', onSeeAll: () => _goToLibrary(3)),
              _horizontalSongList(_oldSongs),
              _sectionHeader('🎸 English Songs', onSeeAll: () => _goToLibrary(0)),
              _horizontalSongList(_englishSongs),
              // Movie Wishes header
              SliverToBoxAdapter(
                child: InkWell(
                  onTap: () => setState(() => _movieWishesExpanded = !_movieWishesExpanded),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 16, 10),
                    child: Row(
                      children: [
                        const Text('🎥 Movie Wishes',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${_movieFolders.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Icon(
                          _movieWishesExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFFB44FE8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Movie chips grid (only when expanded)
              if (_movieWishesExpanded) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      mainAxisExtent: 36,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildListDelegate(
                      _movieFolders.keys.map((name) => GestureDetector(
                        onTap: () => _openMovieSongs(name),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D0B5A), Color(0xFF1A0533)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF7C3AED), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎬', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                // Wished songs
                SliverToBoxAdapter(
                  child: MovieWishesService.instance.songs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
                          child: Text('Tap ⋮ on any song to add to wishes',
                              style: TextStyle(color: Colors.white38, fontSize: 12)),
                        )
                      : SizedBox(
                          height: 155,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: MovieWishesService.instance.songs.length,
                            itemBuilder: (context, i) {
                              final wishes = MovieWishesService.instance.songs;
                              return _SongCard(
                                track: wishes[i],
                                allTracks: List<Track>.from(wishes),
                                index: i,
                              );
                            },
                          ),
                        ),
                ),
              ],
              _sectionHeader('🌐 Browse by Language', onSeeAll: null),
              _languageGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF2D0B5A), Color(0xFF0A0A0F)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 56, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFB44FE8), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('WS Music',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE85D75), size: 22),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.white60, size: 22),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen())),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Good Music, Good Vibes 🎵',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────
  Widget _sectionHeader(String title, {required VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 16, 10),
        child: Row(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: const Text('See all',
                    style: TextStyle(color: Color(0xFFB44FE8), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Horizontal Song List ──────────────────────────────────────
  Widget _horizontalSongList(List<Track> tracks) {
    if (tracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 130,
          child: Center(child: Text('No songs', style: TextStyle(color: Colors.white38))),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 155,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: tracks.length,
          itemBuilder: (context, i) => _SongCard(
            track: tracks[i],
            allTracks: tracks,
            index: i,
          ),
        ),
      ),
    );
  }

  // ── Language Grid ─────────────────────────────────────────────
  Widget _languageGrid() {
    final items = [
      {'emoji': '🎸', 'label': 'English', 'tab': 0, 'color1': const Color(0xFF1565C0), 'color2': const Color(0xFF0D47A1)},
      {'emoji': '🎵', 'label': 'Hindi', 'tab': 1, 'color1': const Color(0xFF6A1B9A), 'color2': const Color(0xFF4A148C)},
      {'emoji': '🥁', 'label': 'Marathi', 'tab': 2, 'color1': const Color(0xFF00695C), 'color2': const Color(0xFF004D40)},
      {'emoji': '🎙️', 'label': 'Old Songs', 'tab': 3, 'color1': const Color(0xFF7C3AED), 'color2': const Color(0xFF4C1D95)},
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: items.map((item) {
            return GestureDetector(
              onTap: () => _goToLibrary(item['tab'] as int),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item['color1'] as Color, item['color2'] as Color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['emoji'] as String, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(item['label'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Movie Songs Bottom Sheet ──────────────────────────────────────
class _MovieSongsSheet extends StatefulWidget {
  const _MovieSongsSheet({required this.movieName, required this.folderName});
  final String movieName;
  final String folderName;
  @override
  State<_MovieSongsSheet> createState() => _MovieSongsSheetState();
}

class _MovieSongsSheetState extends State<_MovieSongsSheet> {
  final _supabase = SupabaseService();
  List<Track> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final songs = await _supabase.fetchSongsFromFolder(widget.folderName);
      if (mounted) setState(() { _songs = songs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 3,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                const Text('🎥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.movieName,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (!_loading)
                  Text('${_songs.length} songs',
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB44FE8)))
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red, fontSize: 13)))
                    : _songs.isEmpty
                        ? const Center(child: Text('No songs found', style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.only(bottom: 30),
                            itemCount: _songs.length,
                            itemBuilder: (ctx, i) {
                              final t = _songs[i];
                              return ListTile(
                                leading: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFF2D0B5A), Color(0xFF1E1E2E)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: const TextStyle(color: Color(0xFFB44FE8), fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                                subtitle: Text(t.artist, maxLines: 1,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_circle_rounded, color: Color(0xFFB44FE8), size: 28),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    RecentlyPlayedService.instance.add(t);
                                    Navigator.push(ctx, MaterialPageRoute(
                                      builder: (_) => TrackDetailScreen(
                                          track: t, tracks: _songs, currentIndex: i),
                                    ));
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  RecentlyPlayedService.instance.add(t);
                                  Navigator.push(ctx, MaterialPageRoute(
                                    builder: (_) => TrackDetailScreen(
                                        track: t, tracks: _songs, currentIndex: i),
                                  ));
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Song Card (horizontal) ────────────────────────────────────────
class _SongCard extends StatefulWidget {
  const _SongCard({required this.track, required this.allTracks, required this.index});
  final Track track;
  final List<Track> allTracks;
  final int index;
  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard> {
  String? _cover;
  bool _coverLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.track.albumCover != null) {
      _cover = widget.track.albumCover;
      _coverLoading = false;
    } else {
      _fetchCover();
    }
  }

  Future<void> _fetchCover() async {
    try {
      final q = Uri.encodeComponent('${widget.track.title} ${widget.track.artist}');
      final res = await http.get(Uri.parse('https://itunes.apple.com/search?term=$q&entity=song&limit=1'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final results = (jsonDecode(res.body)['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          final url = (results.first['artworkUrl100'] as String?)?.replaceAll('100x100bb', '300x300bb');
          if (mounted) setState(() { _cover = url; _coverLoading = false; });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _coverLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RecentlyPlayedService.instance.add(widget.track);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => TrackDetailScreen(
              track: widget.track, tracks: widget.allTracks, currentIndex: widget.index),
        ));
      },
      child: Container(
        width: 115,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _coverLoading
                  ? Container(width: 115, height: 115,
                      color: const Color(0xFF1E1E2E),
                      child: const Center(child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24))))
                  : _cover != null
                      ? Image.network(_cover!, width: 115, height: 115, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
            ),
            const SizedBox(height: 6),
            Text(widget.track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(widget.track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 115, height: 115,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF2D0B5A), Color(0xFF1E1E2E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 32),
  );
}
