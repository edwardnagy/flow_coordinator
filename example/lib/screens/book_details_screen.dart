import 'package:flutter/material.dart';

import '../data/models/book.dart';
import '../data/repositories/book_repository.dart';

class BookDetailsScreen extends StatelessWidget {
  const BookDetailsScreen({super.key, required this.bookID});

  final String bookID;

  @override
  Widget build(BuildContext context) {
    final bookRepository = BookRepository();

    Book? book;
    try {
      book = bookRepository.getBook(bookID: bookID);
    } on StateError {
      book = null;
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book not found')),
        body: const Center(child: Text('The book was not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(book.title), Text(book.authorName)],
        ),
      ),
    );
  }
}
