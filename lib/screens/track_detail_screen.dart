import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
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

class _TrackDetailViewState extends State<_TrackDetailView> {
  final _audio = AudioPlayerService.instance;
  final _favService = FavoritesService.instance;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isFavorite = false;
  Color _bgColor = const Color(0xFF121212);

  late Track _currentTrack;

  static const _themes = [
    {'label': 'Dark', 'color': Color(0xFF121212)},
    {'label': 'Blue', 'color': Color(0xFF0D1B2A)},
    {'label': 'Purple', 'color': Color(0xFF1A0A2E)},
    {'label': 'Green', 'color': Color(0xFF0A1F0A)},
    {'label': 'Red', 'color': Color(0xFF1F0A0A)},
  ];

  @override
  void initState() {
    super.initState();
    _currentTrack = widget.initialTrack;
    _isFavorite = _favService.isFavorite(_currentTrack.id);

    _audio.playerStateStream.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _audio.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audio.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    // sync current track when service changes it (e.g. from MiniPlayer next)
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

  void _goPrev() {
    if (_position.inSeconds > 3) {
      _audio.seek(Duration.zero);
      return;
    }
    _audio.goPrev();
  }

  void _showColorPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Theme',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _themes.map((t) {
                final color = t['color'] as Color;
                final label = t['label'] as String;
                final isSelected = _bgColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() => _bgColor = color);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text('$label color pan change zala'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('NOW PLAYING',
            style: TextStyle(
                fontSize: 12, letterSpacing: 2, color: Colors.white70)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Album Art
            BlocBuilder<TrackDetailBloc, TrackDetailState>(
              builder: (context, state) {
                final cover = (state.status == TrackDetailStatus.success
                        ? state.track?.albumCover
                        : null) ??
                    _currentTrack.albumCover;
                return Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: cover != null
                          ? Image.network(cover,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Title & Artist
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTrack.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentTrack.artist,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white60,
                    size: 28,
                  ),
                  onPressed: () {
                    _favService.toggle(_currentTrack);
                    setState(() =>
                        _isFavorite = _favService.isFavorite(_currentTrack.id));
                  },
                ),
                Tooltip(
                  message: 'Color Theme',
                  child: IconButton(
                    icon: const Icon(Icons.palette_outlined,
                        color: Colors.white60, size: 26),
                    onPressed: () => _showColorPicker(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Progress Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  Text(
                    _duration == Duration.zero ? '--:--' : _fmt(_duration),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Controls
            FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle
                  IconButton(
                    icon: Icon(Icons.shuffle,
                        color: _audio.isShuffled
                            ? Colors.white
                            : Colors.white38,
                        size: 28),
                    onPressed: () =>
                        setState(() => _audio.isShuffled = !_audio.isShuffled),
                  ),
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 40),
                    onPressed: _goPrev,
                  ),
                  // Play / Pause
                  GestureDetector(
                    onTap: _currentTrack.preview != null
                        ? _audio.togglePlay
                        : null,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _currentTrack.preview != null
                            ? Colors.white
                            : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2),
                            )
                          : Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: _currentTrack.preview != null
                                  ? Colors.black
                                  : Colors.white38,
                              size: 36,
                            ),
                    ),
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 40),
                    onPressed: _audio.goNext,
                  ),
                  // Repeat
                  IconButton(
                    icon: Icon(
                      _audio.repeatMode == 2
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: _audio.repeatMode > 0
                          ? Colors.white
                          : Colors.white38,
                      size: 28,
                    ),
                    onPressed: () => setState(
                        () => _audio.repeatMode = (_audio.repeatMode + 1) % 3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_currentTrack.albumTitle != null)
              Text(
                _currentTrack.albumTitle!,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF282828),
        child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
      );
}
