import '../../models/track.dart';

enum LibraryStatus { initial, loading, success, failure }

class LibraryState {
  const LibraryState({
    this.status = LibraryStatus.initial,
    this.tracks = const [],
    this.filteredTracks = const [],
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
  });

  final LibraryStatus status;
  final List<Track> tracks;         // all loaded tracks (master list)
  final List<Track> filteredTracks; // what the UI renders
  final bool hasMore;
  final String? error;
  final String searchQuery;

  bool get isSearching => searchQuery.isNotEmpty;

  LibraryState copyWith({
    LibraryStatus? status,
    List<Track>? tracks,
    List<Track>? filteredTracks,
    bool? hasMore,
    String? error,
    String? searchQuery,
  }) {
    return LibraryState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      filteredTracks: filteredTracks ?? this.filteredTracks,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
