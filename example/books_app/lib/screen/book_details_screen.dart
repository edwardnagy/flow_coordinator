import 'package:flutter/material.dart';

import '../data/book_repository.dart';

class BookDetailsScreen extends StatelessWidget {
  const BookDetailsScreen({
    super.key,
    required this.bookId,
  });

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final book = BookRepository().getBookById(bookId);

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(book.title),
            Text(book.authorName),
            Text(book.category.toString()),
          ],
        ),
      ),
    );
  }
}
