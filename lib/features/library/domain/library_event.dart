abstract class LibraryEvent {}

class LibraryFetchNextPage extends LibraryEvent {}

class LibrarySearchChanged extends LibraryEvent {
  LibrarySearchChanged(this.query);
  final String query;
}

class LibraryClearSearch extends LibraryEvent {}
