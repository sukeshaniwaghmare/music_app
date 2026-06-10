import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _section('Playback'),
          _tile(Icons.high_quality, 'Audio Quality', 'Standard'),
          _tile(Icons.equalizer, 'Equalizer', 'Off'),
          _section('About'),
          _tile(Icons.info_outline, 'App Version', '1.0.0'),
          _tile(Icons.person_outline, 'Developer', 'Waghmare Sukeshani'),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
      );

  Widget _tile(IconData icon, String title, String subtitle) => ListTile(
        leading: Icon(icon, color: Colors.white60),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
      );
}
