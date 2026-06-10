import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../models/track.dart';

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
    _audio.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracks = _audio.tracks;
    final currentIndex = _audio.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Queue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (tracks.length > currentIndex + 1)
            TextButton(
              onPressed: () {
                setState(() {
                  _audio.tracks.removeRange(currentIndex + 1, tracks.length);
                });
              },
              child: const Text('Clear Queue',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
        ],
      ),
      body: tracks.isEmpty
          ? const Center(
              child: Text('Queue is empty',
                  style: TextStyle(color: Colors.white54)))
          : ReorderableListView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final track = _audio.tracks.removeAt(oldIndex);
                  _audio.tracks.insert(newIndex, track);
                  if (oldIndex == currentIndex) {
                    _audio.currentIndex = newIndex;
                  } else if (oldIndex < currentIndex &&
                      newIndex >= currentIndex) {
                    _audio.currentIndex--;
                  } else if (oldIndex > currentIndex &&
                      newIndex <= currentIndex) {
                    _audio.currentIndex++;
                  }
                });
              },
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isCurrent = index == currentIndex;
                final isUpcoming = index > currentIndex;

                return ListTile(
                  key: ValueKey(track.id.toString() + index.toString()),
                  leading: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: track.albumCover != null
                            ? Image.network(track.albumCover!,
                                width: 48, height: 48, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder())
                            : _placeholder(),
                      ),
                      if (isCurrent)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.equalizer,
                              color: Colors.green, size: 20),
                        ),
                    ],
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? Colors.green : Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? Colors.green.shade200 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Text('NOW PLAYING',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold))
                      : IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white38, size: 18),
                          onPressed: () {
                            setState(() => _audio.tracks.removeAt(index));
                          },
                        ),
                  onTap: isUpcoming || index < currentIndex
                      ? () => _audio.play(track, _audio.tracks, index)
                      : null,
                );
              },
            ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        color: const Color(0xFF282828),
        child: const Icon(Icons.music_note, color: Colors.white24, size: 20),
      );
}
