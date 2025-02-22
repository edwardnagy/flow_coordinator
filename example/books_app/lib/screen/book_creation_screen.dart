import 'package:flutter/material.dart';

class BookCreationScreen extends StatelessWidget {
  const BookCreationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ModalRoute.of(context) is RawDialogRoute
            ? const CloseButton()
            : null,
        title: const Text('Create a new book'),
      ),
      body: const Center(
        child: Text('Create a new book'),
      ),
    );
  }
}
