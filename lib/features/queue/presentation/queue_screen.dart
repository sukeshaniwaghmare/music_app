import 'package:flutter/material.dart';
import '../../../core/services/audio_player_service.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});
  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final _audio = AudioPlayerService.instance;

  @override
  void initState() {
    super.initState();
    _audio.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    final tracks = _audio.tracks;
    final currentIndex = _audio.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1A0F), Color(0xFF0A0A0F)],
          ),
        ),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
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
                        color: Colors.greenAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.queue_music_rounded,
                          color: Colors.greenAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Queue',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          Text('${tracks.length} songs',
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (tracks.length > currentIndex + 1)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _audio.tracks.removeRange(currentIndex + 1, tracks.length);
                        }),
                        icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.white38),
                        label: const Text('Clear', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: tracks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.queue_music_rounded, size: 72, color: Colors.white12),
                          SizedBox(height: 16),
                          Text('Queue is empty',
                              style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final track = _audio.tracks.removeAt(oldIndex);
                          _audio.tracks.insert(newIndex, track);
                          if (oldIndex == currentIndex) {
                            _audio.currentIndex = newIndex;
                          } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
                            _audio.currentIndex--;
                          } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
                            _audio.currentIndex++;
                          }
                        });
                      },
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isCurrent = index == currentIndex;
                        return Container(
                          key: ValueKey(track.id.toString() + index.toString()),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF1E3A2E) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrent
                                ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: track.albumCover != null
                                      ? Image.network(track.albumCover!, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                                      : _ph(),
                                ),
                                if (isCurrent)
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.equalizer_rounded, color: Colors.greenAccent, size: 20),
                                  ),
                              ],
                            ),
                            title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isCurrent ? Colors.greenAccent : Colors.white,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14)),
                            subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isCurrent ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.white38,
                                    fontSize: 12)),
                            trailing: isCurrent
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.greenAccent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20)),
                                    child: const Text('PLAYING',
                                        style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
                                    onPressed: () => setState(() => _audio.tracks.removeAt(index)),
                                  ),
                            onTap: index != currentIndex
                                ? () => _audio.play(track, _audio.tracks, index)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 20),
      );
}
