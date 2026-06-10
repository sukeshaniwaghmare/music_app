import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/track.dart';

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._() {
    _player.onPlayerComplete.listen((_) => _onComplete());
  }
  static final instance = AudioPlayerService._();

  final _player = AudioPlayer();

  Track? currentTrack;
  List<Track> tracks = [];
  int currentIndex = 0;
  int repeatMode = 0; // 0=off, 1=repeat all, 2=repeat one
  bool isShuffled = false;

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;

  PlayerState get playerState => _player.state;
  bool get isPlaying => _player.state == PlayerState.playing;

  void _onComplete() {
    if (repeatMode == 2) {
      _player.seek(Duration.zero);
      _player.resume();
    } else if (repeatMode == 1) {
      goNext();
    } else {
      if (currentIndex < tracks.length - 1) goNext();
    }
  }

  Future<void> play(Track track, List<Track> trackList, int index) async {
    currentTrack = track;
    tracks = trackList;
    currentIndex = index;
    notifyListeners();
    if (track.preview == null) return;
    await _player.stop();
    await _player.play(UrlSource(track.preview!));
  }

  Future<void> togglePlay() async {
    if (_player.state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  void goNext() {
    if (tracks.isEmpty) return;
    int nextIndex;
    if (isShuffled) {
      final indices = List.generate(tracks.length, (i) => i)..shuffle();
      nextIndex = indices.firstWhere((i) => i != currentIndex,
          orElse: () => currentIndex);
    } else {
      nextIndex = (currentIndex + 1) % tracks.length;
    }
    play(tracks[nextIndex], tracks, nextIndex);
  }

  void addToQueue(Track track) {
    final insertIndex = currentIndex + 1;
    if (insertIndex < tracks.length) {
      tracks.insert(insertIndex, track);
    } else {
      tracks.add(track);
    }
  }

  void goPrev() {
    if (tracks.isEmpty) return;
    final prevIndex = (currentIndex - 1 + tracks.length) % tracks.length;
    play(tracks[prevIndex], tracks, prevIndex);
  }

  Future<void> seek(Duration pos) => _player.seek(pos);

  Future<void> stop() async {
    currentTrack = null;
    notifyListeners();
    await _player.stop();
  }
}
