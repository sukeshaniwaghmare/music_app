import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0A1F), Color(0xFF0A0A0F)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
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
                          color: const Color(0xFFB44FE8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.settings_rounded,
                            color: Color(0xFFB44FE8), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Settings',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Playback'),
                    const SizedBox(height: 8),
                    _card([
                      _tile(Icons.high_quality_rounded, 'Audio Quality',
                          'Standard', const Color(0xFF4CAF50)),
                      _divider(),
                      _tile(Icons.equalizer_rounded, 'Equalizer', 'Off',
                          const Color(0xFF2196F3)),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('About'),
                    const SizedBox(height: 8),
                    _card([
                      _tile(Icons.music_note_rounded, 'App Name', 'WS Music',
                          const Color(0xFFB44FE8)),
                      _divider(),
                      _tile(Icons.info_outline_rounded, 'App Version', '1.0.0',
                          const Color(0xFF9E9E9E)),
                      _divider(),
                      _tile(Icons.person_rounded, 'Developer',
                          'Waghmare Sukeshani', const Color(0xFFE85D75)),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('Source'),
                    const SizedBox(height: 8),
                    _card([
                      _tile(Icons.api_rounded, 'Music API', 'iTunes Search API',
                          const Color(0xFFFF9800)),
                      _divider(),
                      _tile(Icons.music_video_rounded, 'Preview', '30 sec clips',
                          const Color(0xFF00BCD4)),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(
        height: 1, thickness: 1, color: Colors.white10,
        indent: 56,
      );

  Widget _tile(IconData icon, String title, String value, Color iconColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            Text(value,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
}
