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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recently Played',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tracks.isEmpty
          ? const Center(
              child: Text('No recently played songs',
                  style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return _RecentTile(track: track, tracks: tracks, index: index);
              },
            ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile(
      {required this.track, required this.tracks, required this.index});
  final Track track;
  final List<Track> tracks;
  final int index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackDetailScreen(
            track: track,
            tracks: List<Track>.from(tracks),
            currentIndex: index,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.albumCover != null
                  ? Image.network(track.albumCover!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline,
                  color: Colors.white54, size: 28),
              onPressed: () =>
                  AudioPlayerService.instance.play(track, List<Track>.from(tracks), index),
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
