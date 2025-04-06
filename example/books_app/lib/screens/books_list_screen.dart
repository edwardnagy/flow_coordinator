import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import '../data/book_category.dart';
import '../data/book_repository.dart';

abstract interface class BooksListScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onCategorySelected(BookCategory category);

  void onBookSelected({required String bookID, required BookCategory category});

  void onCreateBook();
}

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key, required this.selectedCategory});

  final BookCategory? selectedCategory;

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen>
    with SingleTickerProviderStateMixin {
  static const _categories = BookCategory.values;

  late final TabController _tabController;

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final newCategory = _categories[_tabController.index];
    if (newCategory != widget.selectedCategory) {
      FlowCoordinator.of<BooksListScreenListener>(context)
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

  Widget _searchBar(BuildContext context) {
    return SearchAnchor(
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0),
          ),
          leading: const Icon(Icons.search),
          hintText: 'Search books',
          onTap: controller.openView,
          onChanged: (_) => controller.openView(),
        );
      },
      suggestionsBuilder: (context, controller) {
        final searchQuery = controller.text;
        final books = BookRepository().searchBooks(searchQuery);

        return List<ListTile>.generate(
          books.length,
          (index) {
            final book = books[index];
            return ListTile(
              title: Text(book.title),
              subtitle: Text(book.authorName),
              onTap: () {
                FlowCoordinator.of<BooksListScreenListener>(context)
                    .onBookSelected(bookID: book.id, category: book.category);
                controller.closeView(searchQuery);
              },
            );
          },
        );
      },
    );
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
      body: Column(
        children: [
          // Padding(
          //   padding: EdgeInsets.only(
          //     top: 16.0 + MediaQuery.paddingOf(context).top,
          //     left: 16.0 + MediaQuery.of(context).padding.left,
          //     right: 16.0 + MediaQuery.of(context).padding.right,
          //     bottom: 8.0,
          //   ),
          //   child: _searchBar(context),
          // ),
          Expanded(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.of(context).padding.copyWith(
                      top: 0.0,
                    ),
              ),
              child: TabBarView(
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
                            FlowCoordinator.of<BooksListScreenListener>(
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          FlowCoordinator.of<BooksListScreenListener>(context).onCreateBook();
        },
        label: const Text('Add Book'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
