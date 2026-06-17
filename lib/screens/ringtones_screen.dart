import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class RingtonesScreen extends StatefulWidget {
  const RingtonesScreen({super.key});
  @override
  State<RingtonesScreen> createState() => _RingtonesScreenState();
}

class _RingtonesScreenState extends State<RingtonesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, List<Track>> _tracks = {'English': [], 'Hindi': [], 'Marathi': []};
  final Map<String, bool> _loading = {'English': false, 'Hindi': false, 'Marathi': false};

  static const _queries = {
    'English': ['top hits english', 'pop songs english', 'ed sheeran', 'taylor swift', 'eminem'],
    'Hindi': ['arijit singh', 'hindi romantic', 'shreya ghoshal hindi', 'kumar sanu', 'atif aslam'],
    'Marathi': ['ajay atul marathi', 'marathi superhit', 'swapnil bandodkar', 'marathi lokgeet', 'bela shende'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetch('English');
    _fetch('Hindi');
    _fetch('Marathi');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch(String lang) async {
    if (_loading[lang]!) return;
    setState(() => _loading[lang] = true);
    final queries = _queries[lang]!;
    final seen = <int>{};
    final results = <Track>[];
    try {
      await Future.wait(queries.map((q) async {
        final uri = Uri.parse(
            'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&entity=song&limit=30&country=IN');
        final res = await http.get(uri).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final list = (jsonDecode(res.body)['results'] as List?) ?? [];
          for (final e in list) {
            final t = Track.fromJson(e as Map<String, dynamic>);
            if (t.preview != null && seen.add(t.id)) results.add(t);
          }
        }
      }));
    } catch (_) {}
    if (mounted) setState(() { _tracks[lang] = results; _loading[lang] = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0A0A0F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 52, 16, 0),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Ringtones', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFB44FE8), size: 22),
                    const SizedBox(width: 8),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Text('30 sec preview • Set as ringtone', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
                TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: '🎸 English (${_tracks['English']!.length})'),
                    Tab(text: '🎵 Hindi (${_tracks['Hindi']!.length})'),
                    Tab(text: '🥁 Marathi (${_tracks['Marathi']!.length})'),
                  ],
                ),
                const SizedBox(height: 4),
              ]),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: ['English', 'Hindi', 'Marathi'].map((lang) => _buildTab(lang)).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(String lang) {
    if (_loading[lang]!) return const Center(child: CircularProgressIndicator(color: Color(0xFFB44FE8)));
    final tracks = _tracks[lang]!;
    if (tracks.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.music_off_rounded, color: Colors.white24, size: 48),
        const SizedBox(height: 12),
        const Text('No ringtones found', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => _fetch(lang), child: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: tracks.length,
      itemBuilder: (_, i) => _RingtoneTile(track: tracks[i]),
    );
  }
}

// ── Ringtone Tile ─────────────────────────────────────────────────
class _RingtoneTile extends StatefulWidget {
  const _RingtoneTile({required this.track});
  final Track track;
  @override
  State<_RingtoneTile> createState() => _RingtoneTileState();
}

class _RingtoneTileState extends State<_RingtoneTile> {
  final _audio = AudioPlayerService.instance;
  bool _downloading = false;
  bool _playing = false;

  void _togglePlay() {
    if (_playing) {
      _audio.togglePlay();
      setState(() => _playing = false);
    } else {
      _audio.play(widget.track, [widget.track], 0);
      setState(() => _playing = true);
    }
  }

  Future<void> _downloadRingtone() async {
    if (widget.track.preview == null) return;
    setState(() => _downloading = true);
    try {
      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Ringtones')
          : await getApplicationDocumentsDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      final fileName = '${widget.track.title.replaceAll(RegExp(r'[^\w\s]'), '').trim()}_ringtone.m4a';
      final filePath = '${dir.path}/$fileName';
      await Dio().download(widget.track.preview!, filePath);

      if (mounted && Platform.isAndroid) {
        // Ask user to set as ringtone via system intent
        final file = File(filePath);
        if (await file.exists()) {
          _showSetRingtoneDialog(filePath, fileName);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved: $fileName'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1565C0),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showSetRingtoneDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Downloaded!', style: TextStyle(color: Colors.white)),
        content: Text('"$fileName" saved to Ringtones folder.\n\nSet as ringtone now?',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _openRingtoneSettings();
            },
            child: const Text('Set Ringtone'),
          ),
        ],
      ),
    );
  }

  void _openRingtoneSettings() {
    const intent = AndroidIntent(
      action: 'android.settings.SOUND_SETTINGS',
    );
    intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: _playing ? Border.all(color: const Color(0xFF1565C0), width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.track.albumCover != null
                ? Image.network(widget.track.albumCover!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          if (_playing)
            Positioned.fill(child: Container(
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
            )),
        ]),
        title: Text(widget.track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _playing ? const Color(0xFF64B5F6) : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(widget.track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: Icon(_playing ? Icons.stop_rounded : Icons.play_circle_outline_rounded,
                color: _playing ? const Color(0xFF64B5F6) : Colors.white54, size: 26),
            onPressed: _togglePlay,
            padding: EdgeInsets.zero,
          ),
          _downloading
              ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1565C0)))
              : IconButton(
                  icon: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF1565C0), size: 26),
                  onPressed: _downloadRingtone,
                  padding: EdgeInsets.zero,
                ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(width: 48, height: 48,
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)])),
    child: const Icon(Icons.music_note_rounded, color: Colors.white38, size: 20));
}
