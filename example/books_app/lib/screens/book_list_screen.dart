import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

import '../data/repositories/book_repository.dart';

abstract interface class BookListScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onBookTabChanged(BookTabType tab);

  void onBookSelected({required String bookID});
}

enum BookTabType { newBooks, allBooks }

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key, required this.tab});

  final BookTabType tab;

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = BookTabType.values;

  final _bookRepository = BookRepository();
  late final TabController _tabController = TabController(
    length: _tabs.length,
    initialIndex: _tabs.indexOf(widget.tab),
    vsync: this,
  )..addListener(_onTabChanged);

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BookListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Wait for the next frame to select the initial tab to avoid marking
    // the widget as needing to build in the build method.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _tabController.index = _tabs.indexOf(widget.tab);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final tab = _tabs[_tabController.index];
    if (tab != widget.tab) {
      FlowCoordinator.of<BookListScreenListener>(context).onBookTabChanged(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs
              .map(
                (tab) => Tab(
                  text: switch (tab) {
                    BookTabType.newBooks => 'New',
                    BookTabType.allBooks => 'All',
                  },
                ),
              )
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map(
          (tab) {
            final books = _bookRepository.getBooks(
              includeOnlyNew: switch (tab) {
                BookTabType.newBooks => true,
                BookTabType.allBooks => false,
              },
            );

            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.authorName),
                  onTap: () {
                    FlowCoordinator.of<BookListScreenListener>(context)
                        .onBookSelected(bookID: book.id);
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
