class Track {
  final int id;
  final String title;
  final String artist;
  final String? albumTitle;
  final String? albumCover;
  final int? duration;
  final String? preview;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.albumTitle,
    this.albumCover,
    this.duration,
    this.preview,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final trackId = json['trackId'];
    final title = json['trackName'] as String? ?? '';
    final artist = json['artistName'] as String? ?? '';
    final millis = json['trackTimeMillis'];
    return Track(
      id: trackId is int ? trackId : (title + artist).hashCode.abs(),
      title: title,
      artist: artist,
      albumTitle: json['collectionName'] as String?,
      albumCover: (json['artworkUrl100'] as String?)?.replaceAll('100x100bb', '300x300bb'),
      duration: millis is int ? millis ~/ 1000 : null,
      preview: json['previewUrl'] as String?,
    );
  }

  factory Track.fromSupabase(Map<String, dynamic> json) {
    return Track(
      id: (json['id'] as int?) ?? json['title'].toString().hashCode.abs(),
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      albumTitle: json['album'] as String?,
      albumCover: json['cover_url'] as String?,
      duration: json['duration'] as int?,
      preview: json['audio_url'] as String?,
    );
  }

  factory Track.fromSaavn(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? '';

    // artists can be map or list
    String artist = '';
    final artistsRaw = json['artists'];
    if (artistsRaw is Map) {
      final primary = artistsRaw['primary'] as List<dynamic>?;
      if (primary != null && primary.isNotEmpty) {
        artist = primary.first['name'] as String? ?? '';
      }
    } else if (artistsRaw is List && artistsRaw.isNotEmpty) {
      artist = artistsRaw.first['name'] as String? ?? '';
    }

    // album
    final albumRaw = json['album'];
    final album = albumRaw is Map ? albumRaw['name'] as String? : null;

    // image — pick highest quality
    String? image;
    final images = json['image'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      image = images.last['url'] as String? ?? images.last['link'] as String?;
    }

    // downloadUrl — pick highest quality (last = 320kbps)
    String? preview;
    final downloadUrls = json['downloadUrl'] as List<dynamic>?;
    if (downloadUrls != null && downloadUrls.isNotEmpty) {
      preview = downloadUrls.last['url'] as String? ?? downloadUrls.last['link'] as String?;
    }

    final duration = json['duration'];

    return Track(
      id: id.isNotEmpty ? id.hashCode.abs() : name.hashCode.abs(),
      title: name,
      artist: artist,
      albumTitle: album,
      albumCover: image,
      duration: duration is int ? duration : (duration is String ? int.tryParse(duration) : null),
      preview: preview,
    );
  }
}
