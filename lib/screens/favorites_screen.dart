import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/favorites_service.dart';
import 'track_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Track> get _favorites => FavoritesService.instance.favorites;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A0A2E), Color(0xFF121212)],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Favorites',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (_favorites.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 72, color: Colors.white24),
                    SizedBox(height: 16),
                    Text('No favorites yet',
                        style: TextStyle(color: Colors.white38, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Tap ❤️ on any song to save it here',
                        style: TextStyle(color: Colors.white24, fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '${_favorites.length} songs',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _favorites[index];
                  return _FavTile(
                    track: track,
                    index: index + 1,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackDetailScreen(
                            track: track,
                            tracks: _favorites,
                            currentIndex: index,
                          ),
                        ),
                      );
                      setState(() {});
                    },
                    onRemove: () => setState(
                        () => FavoritesService.instance.toggle(track)),
                  );
                },
                childCount: _favorites.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavTile extends StatelessWidget {
  const _FavTile({
    required this.track,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  final Track track;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.albumCover != null
                  ? Image.network(track.albumCover!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(track.artist,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: const Color(0xFF282828),
        child: const Icon(Icons.music_note, color: Colors.white24, size: 24),
      );
}
