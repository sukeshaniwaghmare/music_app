import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_player_service.dart';
import '../screens/track_detail_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final _audio = AudioPlayerService.instance;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _playerState = _audio.playerState;
    _audio.playerStateStream.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _audio.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final track = _audio.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isPlaying = _playerState == PlayerState.playing;
    final repeatMode = _audio.repeatMode;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackDetailScreen(
            track: track,
            tracks: _audio.tracks,
            currentIndex: _audio.currentIndex,
          ),
        ),
      ),
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: track.albumCover != null
                  ? Image.network(track.albumCover!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 10),
            // Title & artist
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            // Repeat
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
                color: repeatMode > 0 ? Colors.white : Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _audio.repeatMode = (_audio.repeatMode + 1) % 3),
            ),
            // Play / Pause
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _audio.togglePlay,
            ),
            // Next
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
              onPressed: _audio.goNext,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: const Color(0xFF383838),
        child: const Icon(Icons.music_note, color: Colors.white24, size: 28),
      );
}
