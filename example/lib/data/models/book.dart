class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authorName,
    required this.isNew,
  });

  final String id;
  final String title;
  final String authorName;
  final bool isNew;
}
