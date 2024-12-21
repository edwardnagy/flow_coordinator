import 'package:books_app/data/book.dart';

import 'book_category.dart';

class BookRepository {
  List<Book> getBooksByCategory(BookCategory category) =>
      _mockBooks.where((book) => book.category == category).toList();

  Book getBookById(String bookId) =>
      _mockBooks.firstWhere((book) => book.id == bookId);

  List<Book> searchBooks(String query) => _mockBooks
      .where((book) =>
          book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.authorName.toLowerCase().contains(query.toLowerCase()))
      .toList();
}

const _mockBooks = [
  // Fiction
  Book(
    id: '0',
    title: 'The Great Gatsby',
    authorName: 'F. Scott Fitzgerald',
    category: BookCategory.fiction,
  ),
  Book(
    id: '1',
    title: 'To Kill a Mockingbird',
    authorName: 'Harper Lee',
    category: BookCategory.fiction,
  ),
  Book(
    id: '2',
    title: '1984',
    authorName: 'George Orwell',
    category: BookCategory.fiction,
  ),
  Book(
    id: '3',
    title: 'Pride and Prejudice',
    authorName: 'Jane Austen',
    category: BookCategory.fiction,
  ),
  Book(
    id: '4',
    title: 'The Catcher in the Rye',
    authorName: 'J.D. Salinger',
    category: BookCategory.fiction,
  ),
  Book(
    id: '5',
    title: 'Animal Farm',
    authorName: 'George Orwell',
    category: BookCategory.fiction,
  ),

  // Romance
  Book(
    id: '6',
    title: 'Sense and Sensibility',
    authorName: 'Jane Austen',
    category: BookCategory.romance,
  ),
  Book(
    id: '7',
    title: 'The Notebook',
    authorName: 'Nicholas Sparks',
    category: BookCategory.romance,
  ),
  Book(
    id: '8',
    title: 'Gone with the Wind',
    authorName: 'Margaret Mitchell',
    category: BookCategory.romance,
  ),
  Book(
    id: '9',
    title: 'The Fault in Our Stars',
    authorName: 'John Green',
    category: BookCategory.romance,
  ),
  Book(
    id: '10',
    title: 'Me Before You',
    authorName: 'Jojo Moyes',
    category: BookCategory.romance,
  ),

  // Biography
  Book(
    id: '11',
    title: 'Steve Jobs',
    authorName: 'Walter Isaacson',
    category: BookCategory.biography,
  ),
  Book(
    id: '12',
    title: 'Becoming',
    authorName: 'Michelle Obama',
    category: BookCategory.biography,
  ),
  Book(
    id: '13',
    title: 'The Diary of a Young Girl',
    authorName: 'Anne Frank',
    category: BookCategory.biography,
  ),
];
