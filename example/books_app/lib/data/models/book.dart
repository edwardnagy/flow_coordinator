import 'book_category.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authorName,
    required this.category,
  });

  final String id;
  final String title;
  final String authorName;
  final BookCategory category;
}
