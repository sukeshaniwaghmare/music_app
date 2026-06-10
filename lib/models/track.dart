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

  factory Track.fromSaavn(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? '';
    final artists = json['artists']?['primary'] as List<dynamic>?;
    final artist = (artists != null && artists.isNotEmpty)
        ? (artists.first['name'] as String? ?? '')
        : '';
    final album = json['album']?['name'] as String?;
    final images = json['image'] as List<dynamic>?;
    final image = (images != null && images.isNotEmpty)
        ? images.last['url'] as String?
        : null;
    final downloadUrls = json['downloadUrl'] as List<dynamic>?;
    final preview = (downloadUrls != null && downloadUrls.isNotEmpty)
        ? downloadUrls.first['url'] as String?
        : null;
    return Track(
      id: id.hashCode.abs(),
      title: name,
      artist: artist,
      albumTitle: album,
      albumCover: image,
      preview: preview,
    );
  }
}
