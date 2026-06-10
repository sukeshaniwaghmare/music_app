import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/track.dart';
import '../../repositories/track_repository.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({TrackRepository? repository})
      : _repo = repository ?? TrackRepository(),
        super(const LibraryState()) {
    on<LibraryFetchNextPage>(_onFetchNextPage);
    on<LibrarySearchChanged>(_onSearchChanged);
    on<LibraryClearSearch>(_onClearSearch);
    on<_LibraryApplyFilter>(_onApplyFilter);

    add(LibraryFetchNextPage());
  }

  final TrackRepository _repo;
  final Set<int> _seenIds = {};
  Timer? _debounce;

  Future<void> _onFetchNextPage(
    LibraryFetchNextPage event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.status == LibraryStatus.loading) return;
    if (!_repo.hasMore && state.tracks.isNotEmpty) return;

    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final newTracks = await _repo.fetchNextPage();
      final unique = newTracks.where((t) => _seenIds.add(t.id)).toList();
      final all = [...state.tracks, ...unique];
      emit(state.copyWith(
        status: LibraryStatus.success,
        tracks: all,
        filteredTracks: state.isSearching ? _filter(all, state.searchQuery) : all,
        hasMore: _repo.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LibraryStatus.failure,
        error: e.toString(),
      ));
    }
  }

  void _onSearchChanged(
    LibrarySearchChanged event,
    Emitter<LibraryState> emit,
  ) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = event.query.trim().toLowerCase();
      if (!isClosed) {
        if (q.isEmpty) {
          add(LibraryClearSearch());
        } else {
          // Emit filtered result directly via a new internal event
          add(_LibraryApplyFilter(q));
        }
      }
    });
  }

  Future<void> _onClearSearch(
    LibraryClearSearch event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: '',
      filteredTracks: state.tracks,
      status: LibraryStatus.success,
    ));
  }

  Future<void> _onApplyFilter(
    _LibraryApplyFilter event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredTracks: _filter(state.tracks, event.query),
      status: LibraryStatus.success,
    ));
  }

  List<Track> _filter(List<Track> tracks, String q) {
    return tracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.id.toString().contains(q))
        .toList();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

// Internal event — not exposed publicly
class _LibraryApplyFilter extends LibraryEvent {
  _LibraryApplyFilter(this.query);
  final String query;
}
