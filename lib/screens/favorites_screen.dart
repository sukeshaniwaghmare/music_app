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
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F0A0A), Color(0xFF0A0A0F)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D75).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            color: Color(0xFFE85D75), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Favorites',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('${_favorites.length} songs',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_favorites.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border_rounded,
                          size: 72, color: Colors.white12),
                      SizedBox(height: 16),
                      Text('No favorites yet',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('Tap ❤️ on any song to save it here',
                          style: TextStyle(color: Colors.white24, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = _favorites[index];
                    return _FavTile(
                      track: track,
                      index: index,
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
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: track.albumCover != null
                  ? Image.network(track.albumCover!,
                      width: 54, height: 54, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ph())
                  : _ph(),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(track.artist,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_rounded,
                  color: Color(0xFFE85D75), size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 22),
      );
}
