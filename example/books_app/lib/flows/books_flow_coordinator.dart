import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/book_category.dart';
import '../screens/book_details_screen.dart';
import '../screens/books_list_screen.dart';

abstract interface class BooksFlowListener<T extends StatefulWidget>
    extends State<T> {
  void onCreateBook();
}

class BooksFlowCoordinator extends StatefulWidget {
  const BooksFlowCoordinator({super.key});

  @override
  State<BooksFlowCoordinator> createState() => _BooksFlowCoordinatorState();
}

class _BooksFlowCoordinatorState
    extends FlowCoordinatorState<BooksFlowCoordinator>
    implements BooksListScreenListener<BooksFlowCoordinator> {
  @override
  List<Page> get initialPages => [_Pages.booksListPage(selectedCategory: null)];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    // Parse the route information.
    final category = switch (routeInformation.uri.queryParameters['category']) {
      'fiction' => BookCategory.fiction,
      'romance' => BookCategory.romance,
      'biography' => BookCategory.biography,
      _ => null
    };
    final bookID = routeInformation.uri.pathSegments.firstOrNull;

    // Set up the navigation stack.
    flowNavigator.setPages([
      _Pages.booksListPage(selectedCategory: category),
      if (bookID != null)
        _Pages.bookDetailPage(category: category, bookID: bookID),
    ]);

    return SynchronousFuture(null);
  }

  @override
  void onCategorySelected(BookCategory category) {
    flowNavigator.setPages([
      _Pages.booksListPage(selectedCategory: category),
    ]);
  }

  @override
  void onBookSelected({
    required String bookID,
    required BookCategory category,
  }) {
    flowNavigator.push(
      _Pages.bookDetailPage(category: category, bookID: bookID),
    );
  }

  @override
  void onCreateBook() {
    FlowCoordinator.of<BooksFlowListener>(context).onCreateBook();
  }
}

class _Pages {
  static Page booksListPage({required BookCategory? selectedCategory}) =>
      MaterialPage(
        key: const ValueKey('booksListPage'),
        child: FlowRouteSubtree(
          routeInformation: RouteInformation(
            uri: Uri(
              queryParameters: selectedCategory?.toQueryParameters(),
            ),
          ),
          child: BooksListScreen(selectedCategory: selectedCategory),
        ),
      );

  static Page bookDetailPage({
    required BookCategory? category,
    required String bookID,
  }) =>
      MaterialPage(
        key: ValueKey('bookDetailPage_$bookID'),
        child: FlowRouteSubtree(
          routeInformation: RouteInformation(
            uri: Uri(
              pathSegments: [bookID],
              queryParameters: category?.toQueryParameters(),
            ),
          ),
          child: BookDetailsScreen(bookID: bookID),
        ),
      );
}

extension on BookCategory {
  Map<String, String> toQueryParameters() => {
        'category': switch (this) {
          BookCategory.fiction => 'fiction',
          BookCategory.romance => 'romance',
          BookCategory.biography => 'biography',
        },
      };
}
