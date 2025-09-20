import 'package:books_app/data/models/book.dart';

import '../models/book_category.dart';

class BookRepository {
  List<Book> getBooksByCategory(BookCategory category) =>
      _mockBooks.where((book) => book.category == category).toList();

  Book getBookByID(String bookID) =>
      _mockBooks.firstWhere((book) => book.id == bookID);

  List<Book> searchBooks(String query) => _mockBooks
      .where((book) =>
          book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.authorName.toLowerCase().contains(query.toLowerCase()))
      .toList();
}

const _mockBooks = [
  // Fiction
  Book(
    id: 'the-great-gatsby',
    title: 'The Great Gatsby',
    authorName: 'F. Scott Fitzgerald',
    category: BookCategory.fiction,
  ),
  Book(
    id: 'to-kill-a-mockingbird',
    title: 'To Kill a Mockingbird',
    authorName: 'Harper Lee',
    category: BookCategory.fiction,
  ),
  Book(
    id: '1984',
    title: '1984',
    authorName: 'George Orwell',
    category: BookCategory.fiction,
  ),
  Book(
    id: 'pride-and-prejudice',
    title: 'Pride and Prejudice',
    authorName: 'Jane Austen',
    category: BookCategory.fiction,
  ),
  Book(
    id: 'the-catcher-in-the-rye',
    title: 'The Catcher in the Rye',
    authorName: 'J.D. Salinger',
    category: BookCategory.fiction,
  ),
  Book(
    id: 'animal-farm',
    title: 'Animal Farm',
    authorName: 'George Orwell',
    category: BookCategory.fiction,
  ),

  // Romance
  Book(
    id: 'sense-and-sensibility',
    title: 'Sense and Sensibility',
    authorName: 'Jane Austen',
    category: BookCategory.romance,
  ),
  Book(
    id: 'the-notebook',
    title: 'The Notebook',
    authorName: 'Nicholas Sparks',
    category: BookCategory.romance,
  ),
  Book(
    id: 'gone-with-the-wind',
    title: 'Gone with the Wind',
    authorName: 'Margaret Mitchell',
    category: BookCategory.romance,
  ),
  Book(
    id: 'the-fault-in-our-stars',
    title: 'The Fault in Our Stars',
    authorName: 'John Green',
    category: BookCategory.romance,
  ),
  Book(
    id: 'me-before-you',
    title: 'Me Before You',
    authorName: 'Jojo Moyes',
    category: BookCategory.romance,
  ),

  // Biography
  Book(
    id: 'steve-jobs',
    title: 'Steve Jobs',
    authorName: 'Walter Isaacson',
    category: BookCategory.biography,
  ),
  Book(
    id: 'becoming',
    title: 'Becoming',
    authorName: 'Michelle Obama',
    category: BookCategory.biography,
  ),
  Book(
    id: 'the-diary-of',
    title: 'The Diary of a Young Girl',
    authorName: 'Anne Frank',
    category: BookCategory.biography,
  ),
];
