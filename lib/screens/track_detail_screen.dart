import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/track_detail/track_detail_bloc.dart';
import '../blocs/track_detail/track_detail_event.dart';
import '../blocs/track_detail/track_detail_state.dart';
import '../models/track.dart';
import '../services/favorites_service.dart';
import '../services/audio_player_service.dart';

class TrackDetailScreen extends StatelessWidget {
  const TrackDetailScreen({
    super.key,
    required this.track,
    required this.tracks,
    required this.currentIndex,
  });
  final Track track;
  final List<Track> tracks;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackDetailBloc()..add(TrackDetailFetch(track.id)),
      child: _TrackDetailView(
        initialTrack: track,
        tracks: tracks,
        currentIndex: currentIndex,
      ),
    );
  }
}

class _TrackDetailView extends StatefulWidget {
  const _TrackDetailView({
    required this.initialTrack,
    required this.tracks,
    required this.currentIndex,
  });
  final Track initialTrack;
  final List<Track> tracks;
  final int currentIndex;

  @override
  State<_TrackDetailView> createState() => _TrackDetailViewState();
}

class _TrackDetailViewState extends State<_TrackDetailView>
    with SingleTickerProviderStateMixin {
  final _audio = AudioPlayerService.instance;
  final _favService = FavoritesService.instance;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isFavorite = false;
  late Track _currentTrack;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _currentTrack = widget.initialTrack;
    _isFavorite = _favService.isFavorite(_currentTrack.id);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _audio.playerStateStream.listen((s) {
      if (mounted) {
        setState(() => _playerState = s);
        if (s == PlayerState.playing) {
          _rotationController.forward();
        } else {
          _rotationController.stop();
        }
      }
    });
    _audio.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audio.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audio.addListener(() {
      if (mounted && _audio.currentTrack != null) {
        setState(() {
          _currentTrack = _audio.currentTrack!;
          _isFavorite = _favService.isFavorite(_currentTrack.id);
        });
        context.read<TrackDetailBloc>().add(TrackDetailFetch(_currentTrack.id));
      }
    });

    _audio.play(_currentTrack, widget.tracks, widget.currentIndex);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _goPrev() {
    if (_position.inSeconds > 3) {
      _audio.seek(Duration.zero);
      return;
    }
    _audio.goPrev();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final isLoading = _playerState == PlayerState.stopped &&
        _currentTrack.preview != null &&
        _duration == Duration.zero;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0533), Color(0xFF0A0A0F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 32, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text('NOW PLAYING',
                              style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? const Color(0xFFE85D75) : Colors.white38,
                        size: 24,
                      ),
                      onPressed: () {
                        _favService.toggle(_currentTrack);
                        setState(() => _isFavorite = _favService.isFavorite(_currentTrack.id));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white38, size: 22),
                      onPressed: () {
                        Share.share(
                          '🎵 ${_currentTrack.title} - ${_currentTrack.artist}\n\nWS Music App वर ऐका!',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Album Art (rotating disc) ──
              BlocBuilder<TrackDetailBloc, TrackDetailState>(
                builder: (context, state) {
                  final cover = (state.status == TrackDetailStatus.success
                          ? state.track?.albumCover
                          : null) ??
                      _currentTrack.albumCover;
                  return Center(
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (_, child) => Transform.rotate(
                        angle: isPlaying
                            ? _rotationController.value * 2 * 3.14159
                            : 0,
                        child: child,
                      ),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB44FE8).withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: cover != null
                              ? Image.network(cover,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder())
                              : _placeholder(),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── Title & Artist ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      _currentTrack.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentTrack.artist,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Progress Slider ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: const Color(0xFFB44FE8),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        overlayColor: const Color(0x33B44FE8),
                      ),
                      child: Slider(
                        value: progress.toDouble(),
                        onChanged: _currentTrack.preview != null
                            ? (v) => _audio.seek(Duration(
                                milliseconds: (v * _duration.inMilliseconds).round()))
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(_position),
                              style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          Text(
                            _duration == Duration.zero ? '--:--' : _fmt(_duration),
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Controls ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    _ctrlBtn(
                      icon: Icons.shuffle_rounded,
                      size: 22,
                      color: _audio.isShuffled ? const Color(0xFFB44FE8) : Colors.white38,
                      onTap: () => setState(() => _audio.isShuffled = !_audio.isShuffled),
                    ),
                    // Previous
                    _ctrlBtn(
                      icon: Icons.skip_previous_rounded,
                      size: 38,
                      color: Colors.white,
                      onTap: _goPrev,
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: _currentTrack.preview != null ? _audio.togglePlay : null,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB44FE8), Color(0xFF7C3AED)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB44FE8).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                    // Next
                    _ctrlBtn(
                      icon: Icons.skip_next_rounded,
                      size: 38,
                      color: Colors.white,
                      onTap: _audio.goNext,
                    ),
                    // Repeat
                    _ctrlBtn(
                      icon: _audio.repeatMode == 2
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 22,
                      color: _audio.repeatMode > 0 ? const Color(0xFFB44FE8) : Colors.white38,
                      onTap: () => setState(
                          () => _audio.repeatMode = (_audio.repeatMode + 1) % 3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Album name ──
              if (_currentTrack.albumTitle != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.album_rounded, size: 13, color: Colors.white24),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _currentTrack.albumTitle!,
                          style: const TextStyle(color: Colors.white24, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctrlBtn({required IconData icon, required double size, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: color),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF1E1E2E),
        child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.white12),
      );
}
