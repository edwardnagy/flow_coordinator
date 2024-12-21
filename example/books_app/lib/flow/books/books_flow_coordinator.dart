import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/book_category.dart';
import '../../screen/book_details_screen.dart';
import '../../screen/books_list_screen.dart';

part 'books_flow_route_information_parser.dart';
part 'books_flow_state.dart';

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
    extends FlowCoordinatorState<BooksFlowCoordinator, BooksFlowState>
    implements BooksListScreenListener<BooksFlowCoordinator> {
  @override
  List<Page> get initialPages => [
        _Pages.booksByCategoryPage(selectedCategory: null),
      ];

  @override
  final routeInformationParser = BooksFlowRouteInformationParser();

  @override
  Future<void> setNewState(BooksFlowState flowState) {
    flowNavigator.setPages([
      _Pages.booksByCategoryPage(selectedCategory: flowState.category),
      if (flowState.bookId case final bookId?)
        _Pages.bookDetailsPage(bookId: bookId, category: flowState.category)
    ]);

    return SynchronousFuture(null);
  }

  @override
  void onCategorySelected(BookCategory category) {
    final newState = BooksFlowState(category: category);
    setNewState(newState);
  }

  @override
  void onBookSelected({
    required String bookId,
    required BookCategory category,
  }) {
    final newState = BooksFlowState(bookId: bookId, category: category);
    setNewState(newState);
  }

  @override
  void onCreateBook() =>
      FlowCoordinator.of<BooksFlowListener>(context).onCreateBook();
}

class _Pages {
  static Page booksByCategoryPage({
    required BookCategory? selectedCategory,
  }) =>
      FlowStatePageWrapper(
        flowState: BooksFlowState(category: selectedCategory),
        page: MaterialPage(
          key: const ValueKey('booksByCategoryPage'),
          child: BooksListScreen(selectedCategory: selectedCategory),
        ),
      );

  static Page bookDetailsPage({
    required String bookId,
    required BookCategory? category,
  }) =>
      FlowStatePageWrapper(
        flowState: BooksFlowState(bookId: bookId, category: category),
        page: MaterialPage(
          key: ValueKey('bookDetailPage_$bookId'),
          child: BookDetailsScreen(bookId: bookId),
        ),
      );
}
