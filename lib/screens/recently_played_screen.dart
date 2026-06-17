import 'package:flutter/material.dart';
import '../services/recently_played_service.dart';
import '../services/audio_player_service.dart';
import '../models/track.dart';
import 'track_detail_screen.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracks = RecentlyPlayedService.instance.tracks;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1F2E), Color(0xFF0A0A0F)],
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
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history_rounded,
                            color: Colors.blueAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recently Played',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('${tracks.length} songs',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (tracks.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 72, color: Colors.white12),
                      SizedBox(height: 16),
                      Text('No history yet',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('Play a song to see it here',
                          style: TextStyle(color: Colors.white24, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    return InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TrackDetailScreen(
                            track: track,
                            tracks: List<Track>.from(tracks),
                            currentIndex: index),
                      )),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_circle_rounded,
                                  color: Color(0xFFB44FE8), size: 28),
                              onPressed: () => AudioPlayerService.instance
                                  .play(track, List<Track>.from(tracks), index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: tracks.length,
                ),
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
