import '../models/book.dart';

class BookRepository {
  List<Book> getBooks({bool includeOnlyNew = false}) {
    if (includeOnlyNew) {
      return _mockBooks.where((book) => book.isNew).toList();
    }
    return _mockBooks;
  }

  Book getBook({required String bookID}) =>
      _mockBooks.firstWhere((book) => book.id == bookID);
}

const _mockBooks = [
  Book(
    id: 'mystic-river',
    title: 'Mystic River',
    authorName: 'John Doe',
    isNew: true,
  ),
  Book(
    id: 'shadows-of-the-past',
    title: 'Shadows of the Past',
    authorName: 'Jane Smith',
    isNew: false,
  ),
  Book(
    id: 'whispers-in-the-dark',
    title: 'Whispers in the Dark',
    authorName: 'Emily Johnson',
    isNew: true,
  ),
  Book(
    id: 'echoes-of-silence',
    title: 'Echoes of Silence',
    authorName: 'Michael Brown',
    isNew: false,
  ),
  Book(
    id: 'the-forgotten-path',
    title: 'The Forgotten Path',
    authorName: 'Sarah Davis',
    isNew: true,
  ),
  Book(
    id: 'beneath-the-stars',
    title: 'Beneath the Stars',
    authorName: 'Chris Wilson',
    isNew: false,
  ),
  Book(
    id: 'the-lost-chronicles',
    title: 'The Lost Chronicles',
    authorName: 'Laura Martinez',
    isNew: true,
  ),
  Book(
    id: 'secrets-of-the-forest',
    title: 'Secrets of the Forest',
    authorName: 'James Anderson',
    isNew: false,
  ),
  Book(
    id: 'the-hidden-truth',
    title: 'The Hidden Truth',
    authorName: 'Patricia Thomas',
    isNew: true,
  ),
  Book(
    id: 'journey-to-the-unknown',
    title: 'Journey to the Unknown',
    authorName: 'Robert Garcia',
    isNew: false,
  ),
];
