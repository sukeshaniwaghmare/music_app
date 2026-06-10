import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/library/library_bloc.dart';
import '../blocs/library/library_event.dart';
import '../blocs/library/library_state.dart';
import '../models/track.dart';
import 'track_detail_screen.dart';
import 'favorites_screen.dart';
import 'recently_played_screen.dart';
import 'settings_screen.dart';
import 'queue_screen.dart';
import '../services/recently_played_service.dart';
import '../services/favorites_service.dart';
import '../services/audio_player_service.dart';
import '../services/saavn_api_service.dart';
import '../widgets/mini_player.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Saavn state
  final _saavnApi = SaavnApiService();
  final List<Track> _saavnTracks = [];
  bool _saavnLoading = false;
  bool _saavnHasMore = true;
  String? _saavnError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSaavn();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

Future<void> _fetchSaavn() async {
    if (_saavnLoading || !_saavnHasMore) return;
    setState(() => _saavnLoading = true);
    try {
      final tracks = await _saavnApi.fetchNextPage();
      setState(() {
        _saavnTracks.addAll(tracks);
        _saavnHasMore = _saavnApi.hasMore;
        _saavnLoading = false;
        _saavnError = null;
      });
    } catch (e) {
      setState(() {
        _saavnLoading = false;
        _saavnError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: const MiniPlayer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF4A1060), Color(0xFF121212)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('WS Music',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: const Color(0xFF282828),
                        onSelected: (value) {
                          if (value == 'favorites') {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const FavoritesScreen()));
                          } else if (value == 'queue') {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const QueueScreen()));
                          } else if (value == 'recent') {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const RecentlyPlayedScreen()));
                          } else if (value == 'settings') {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const SettingsScreen()));
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'favorites',
                            child: Row(children: [
                              Icon(Icons.favorite, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text('Favorites', style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'queue',
                            child: Row(children: [
                              Icon(Icons.queue_music, color: Colors.white60, size: 20),
                              SizedBox(width: 12),
                              Text('Queue', style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'recent',
                            child: Row(children: [
                              Icon(Icons.history, color: Colors.white60, size: 20),
                              SizedBox(width: 12),
                              Text('Recently Played', style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Row(children: [
                              Icon(Icons.settings, color: Colors.white60, size: 20),
                              SizedBox(width: 12),
                              Text('Settings', style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white38, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white38, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<LibraryBloc>()
                                      .add(LibraryClearSearch());
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) {
                        setState(() {});
                        context
                            .read<LibraryBloc>()
                            .add(LibrarySearchChanged(v));
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.purpleAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    tabs: [
                      BlocBuilder<LibraryBloc, LibraryState>(
                        builder: (context, state) => Tab(
                          text: 'English (${state.tracks.length})',
                        ),
                      ),
                      Tab(text: 'Hindi/Marathi (${_saavnTracks.length})'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _iTunesTab(),
            _saavnTab(),
          ],
        ),
      ),
    );
  }

  Widget _iTunesTab() {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        if (state.status == LibraryStatus.initial ||
            (state.status == LibraryStatus.loading && state.tracks.isEmpty)) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.green));
        }
        if (state.status == LibraryStatus.failure && state.tracks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 64, color: Colors.white38),
                const SizedBox(height: 16),
                Text(state.error ?? 'Error',
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<LibraryBloc>().add(LibraryFetchNextPage()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final tracks = state.filteredTracks;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
              if (state.status != LibraryStatus.loading &&
                  state.hasMore &&
                  !state.isSearching) {
                context.read<LibraryBloc>().add(LibraryFetchNextPage());
              }
            }
            return false;
          },
          child: ListView.builder(
            itemCount: tracks.length + 1,
            itemBuilder: (context, index) {
              if (index >= tracks.length) {
                if (state.status == LibraryStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.green)),
                  );
                }
                return const SizedBox(height: 32);
              }
              return _TrackTile(
                track: tracks[index],
                allTracks: tracks,
                index: index,
                onTap: () {
                  RecentlyPlayedService.instance.add(tracks[index]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackDetailScreen(
                        track: tracks[index],
                        tracks: tracks,
                        currentIndex: index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _saavnTab() {
    if (_saavnTracks.isEmpty && _saavnLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.green));
    }
    if (_saavnTracks.isEmpty && _saavnError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            const Text('Failed to load',
                style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSaavn,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
          _fetchSaavn();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _saavnTracks.length + 1,
        itemBuilder: (context, index) {
          if (index >= _saavnTracks.length) {
            if (_saavnLoading) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: CircularProgressIndicator(color: Colors.green)),
              );
            }
            return const SizedBox(height: 32);
          }
          final tracks = _saavnTracks;
          return _TrackTile(
            track: tracks[index],
            allTracks: tracks,
            index: index,
            onTap: () {
              RecentlyPlayedService.instance.add(tracks[index]);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackDetailScreen(
                    track: tracks[index],
                    tracks: tracks,
                    currentIndex: index,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TrackTile extends StatefulWidget {
  const _TrackTile(
      {required this.track,
      required this.allTracks,
      required this.index,
      required this.onTap});

  final Track track;
  final List<Track> allTracks;
  final int index;
  final VoidCallback onTap;

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> {
  final _fav = FavoritesService.instance;
  final _audio = AudioPlayerService.instance;

  void _showOptions() {
    final isFav = _fav.isFavorite(widget.track.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: widget.track.albumCover != null
                      ? Image.network(widget.track.albumCover!,
                          width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ph48())
                      : _ph48(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(widget.track.artist,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white70),
            title: const Text('Play Now',
                style: TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.pop(context);
              RecentlyPlayedService.instance.add(widget.track);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackDetailScreen(
                    track: widget.track,
                    tracks: widget.allTracks,
                    currentIndex: widget.index,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music, color: Colors.white70),
            title: const Text('Add to Queue',
                style: TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.pop(context);
              _audio.addToQueue(widget.track);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Added to queue'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View Queue',
                    textColor: Colors.green,
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QueueScreen())),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.white70,
            ),
            title: Text(
              isFav ? 'Remove from Favorites' : 'Add to Favorites',
              style: TextStyle(color: isFav ? Colors.red : Colors.white70),
            ),
            onTap: () {
              Navigator.pop(context);
              _fav.toggle(widget.track);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isFav
                    ? 'Removed from favorites'
                    : 'Added to favorites'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: widget.track.albumCover != null
                  ? Image.network(widget.track.albumCover!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ph52())
                  : _ph52(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(widget.track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showOptions,
              child: const Icon(Icons.more_vert,
                  color: Colors.white38, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph48() => Container(
      width: 48,
      height: 48,
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, color: Colors.white24, size: 20));

  Widget _ph52() => Container(
      width: 52,
      height: 52,
      color: const Color(0xFF282828),
      child: const Icon(Icons.music_note, color: Colors.white24, size: 24));
}
