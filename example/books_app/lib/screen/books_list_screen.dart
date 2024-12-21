import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import '../data/book_category.dart';
import '../data/book_repository.dart';

abstract interface class BooksListScreenListener<T extends StatefulWidget>
    extends State<T> {
  void onCategorySelected(BookCategory category);

  void onBookSelected({required String bookId, required BookCategory category});

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

  late final _tabController = TabController(
    length: _categories.length,
    initialIndex: 0,
    vsync: this,
  );

  void _updateSelectedTab() {
    if (widget.selectedCategory case final selectedCategory?) {
      _tabController.index = _categories.indexOf(selectedCategory);
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSelectedTab();
  }

  @override
  void didUpdateWidget(covariant BooksListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _updateSelectedTab();
    }
  }

  @override
  void dispose() {
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
                    .onBookSelected(
                  bookId: book.id,
                  category: book.category,
                );
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
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 16.0 + MediaQuery.paddingOf(context).top,
              left: 16.0 + MediaQuery.of(context).padding.left,
              right: 16.0 + MediaQuery.of(context).padding.right,
              bottom: 8.0,
            ),
            child: _searchBar(context),
          ),
          TabBar(
            controller: _tabController,
            onTap: (index) {
              FlowCoordinator.of<BooksListScreenListener>(context)
                  .onCategorySelected(_categories[index]);
            },
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
                              bookId: book.id,
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
          FlowCoordinator.of<BooksListScreenListener>(context)
              .onCreateBook();
        },
        label: const Text('Add Book'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
