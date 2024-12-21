part of 'books_flow_coordinator.dart';

class BooksFlowState {
  BooksFlowState({
    this.category,
    this.bookId,
  });

  final BookCategory? category;
  final String? bookId;
}
