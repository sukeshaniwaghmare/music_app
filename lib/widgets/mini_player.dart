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
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _playerState = _audio.playerState;
    _audio.playerStateStream.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _audio.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audio.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
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
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

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
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D0B5A), Color(0xFF1A1A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB44FE8).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar on top
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB44FE8)),
                minHeight: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: track.albumCover != null
                        ? Image.network(track.albumCover!,
                            width: 46, height: 46, fit: BoxFit.cover,
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
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Prev
                  _btn(Icons.skip_previous_rounded, 22, _audio.goPrev),
                  // Play/Pause
                  GestureDetector(
                    onTap: _audio.togglePlay,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFB44FE8), Color(0xFF7C3AED)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  // Next
                  _btn(Icons.skip_next_rounded, 22, _audio.goNext),
                  // Close
                  _btn(Icons.close_rounded, 18, () {
                    _audio.stop();
                    setState(() {});
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, double size, VoidCallback onTap) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      icon: Icon(icon, color: Colors.white70, size: size),
      onPressed: onTap,
    );
  }

  Widget _placeholder() => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 22),
      );
}
