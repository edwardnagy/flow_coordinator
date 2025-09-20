import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import '../data/models/book_category.dart';
import '../data/repositories/book_repository.dart';

abstract interface class BookListScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onCategorySelected(BookCategory category);

  void onBookSelected({required String bookID, required BookCategory category});
}

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key, required this.selectedCategory});

  final BookCategory? selectedCategory;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen>
    with SingleTickerProviderStateMixin {
  static const _categories = BookCategory.values;

  late final TabController _tabController;

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final newCategory = _categories[_tabController.index];
    if (newCategory != widget.selectedCategory) {
      FlowCoordinator.of<BookListScreenListener>(context)
          .onCategorySelected(newCategory);
    }
  }

  @override
  void initState() {
    super.initState();
    final int initialTabIndex;
    if (widget.selectedCategory case final selectedCategory?) {
      initialTabIndex = _categories.indexOf(selectedCategory);
    } else {
      initialTabIndex = 0;
    }
    _tabController = TabController(
      length: _categories.length,
      initialIndex: initialTabIndex,
      vsync: this,
    )..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the next frame to select the initial tab to avoid marking
    // the widget as needing to build in the build method.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _tabController.index =
          _categories.indexOf(widget.selectedCategory ?? _categories.first);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories
              .map(
                (category) => Tab(
                  text: switch (category) {
                    BookCategory.fiction => 'Fiction',
                    BookCategory.romance => 'Romance',
                    BookCategory.biography => 'Biography',
                  },
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map(
          (category) {
            final books = BookRepository().getBooksByCategory(category);

            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.authorName),
                  onTap: () {
                    FlowCoordinator.of<BookListScreenListener>(
                      context,
                    ).onBookSelected(
                      bookID: book.id,
                      category: category,
                    );
                  },
                );
              },
            );
          },
        ).toList(),
      ),
    );
  }
}
