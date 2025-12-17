import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/book_details_screen.dart';
import '../screens/book_list_screen.dart';

class BooksFlowCoordinator extends StatefulWidget {
  const BooksFlowCoordinator({super.key});

  static String pathForSelectedBook({required String bookID}) => bookID;

  @override
  State<BooksFlowCoordinator> createState() => _BooksFlowCoordinatorState();
}

class _BooksFlowCoordinatorState extends State<BooksFlowCoordinator>
    with FlowCoordinatorMixin
    implements BookListScreenListener<BooksFlowCoordinator> {
  static const _defaultBookTab = BookTabType.newBooks;

  @override
  List<Page> get initialPages => [_Pages.booksListPage(_defaultBookTab)];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    // Parse the route information.
    final pathSegments = routeInformation.uri.pathSegments;
    final BookTabType bookTab;
    String? bookID;
    switch (pathSegments.firstOrNull) {
      case null:
        bookTab = _defaultBookTab;
      case 'new':
        bookTab = BookTabType.newBooks;
      case 'all':
        bookTab = BookTabType.allBooks;
      case final id:
        bookTab = BookTabType.allBooks;
        bookID = id;
    }

    // Set up the navigation stack.
    flowNavigator.setPages([
      _Pages.booksListPage(bookTab),
      if (bookID != null) _Pages.bookDetailPage(bookID: bookID),
    ]);

    return SynchronousFuture(null);
  }

  @override
  void onBookTabChanged(BookTabType tab) {
    flowNavigator.setPages([
      _Pages.booksListPage(tab),
    ]);
  }

  @override
  void onBookSelected({required String bookID}) {
    flowNavigator.push(
      _Pages.bookDetailPage(bookID: bookID),
    );
  }
}

class _Pages {
  static Page booksListPage(BookTabType tab) => MaterialPage(
        key: const ValueKey('booksListPage'),
        child: FlowRouteScope(
          routeInformation: RouteInformation(
            uri: Uri(
              pathSegments: [
                switch (tab) {
                  BookTabType.newBooks => 'new',
                  BookTabType.allBooks => 'all',
                },
              ],
            ),
          ),
          child: BookListScreen(tab: tab),
        ),
      );

  static Page bookDetailPage({
    required String bookID,
  }) =>
      MaterialPage(
        key: ValueKey('bookDetailPage_$bookID'),
        child: FlowRouteScope(
          routeInformation: RouteInformation(
            uri: Uri(
              path: BooksFlowCoordinator.pathForSelectedBook(bookID: bookID),
            ),
          ),
          child: BookDetailsScreen(bookID: bookID),
        ),
      );
}
