import 'dart:math';

import '../data/repositories/book_repository.dart';
import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/settings_screen.dart';
import 'books_flow_coordinator.dart';

class HomeFlowCoordinator extends StatefulWidget {
  const HomeFlowCoordinator({super.key});

  @override
  State<HomeFlowCoordinator> createState() => _HomeFlowCoordinatorState();
}

class _HomeFlowCoordinatorState extends State<HomeFlowCoordinator>
    with FlowCoordinatorMixin
    implements
        HomeScreenListener<HomeFlowCoordinator>,
        SettingsScreenListener<HomeFlowCoordinator> {
  final _bookRepository = BookRepository();

  @override
  List<Page> get initialPages => [_Pages.homePage(currentTab: HomeTab.books)];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    // Parse the route information.
    final homeTab = switch (routeInformation.uri.pathSegments.firstOrNull) {
      null || '' || 'books' => HomeTab.books,
      'settings' => HomeTab.settings,
      _ => null,
    };

    // Set up the navigation stack.
    flowNavigator.setPages([
      _Pages.homePage(currentTab: homeTab),
      if (homeTab == null) _Pages.notFoundPage(),
    ]);

    // Return the route information for the nested flows.
    final childRouteInformation = RouteInformation(
      uri: Uri(pathSegments: routeInformation.uri.pathSegments.skip(1)),
    );
    return SynchronousFuture(childRouteInformation);
  }

  @override
  void onTabSelected(HomeTab tab) {
    flowNavigator.setPages([_Pages.homePage(currentTab: tab)]);
  }

  @override
  void resetNavigationStackForTab(HomeTab tab) {
    final newRouteInformation = RouteInformation(
      uri: Uri(
        path: switch (tab) {
          HomeTab.books => 'books',
          HomeTab.settings => 'settings',
        },
      ),
    );
    setNewRouteInformation(newRouteInformation);
  }

  @override
  void openRandomBook() {
    final books = _bookRepository.getBooks();
    final randomBookIndex = Random().nextInt(books.length);
    final randomBook = books[randomBookIndex];
    final routeInformation = RouteInformation(
      uri: Uri(
        pathSegments: [
          'books',
          BooksFlowCoordinator.pathForSelectedBook(bookID: randomBook.id),
        ],
      ),
    );
    setNewRouteInformation(routeInformation);
  }
}

class _Pages {
  static Page notFoundPage() => const MaterialPage(
    key: ValueKey('notFoundPage'),
    child: NotFoundScreen(),
  );

  static Page homePage({required HomeTab? currentTab}) {
    return MaterialPage(
      key: const ValueKey('homePage'),
      child: HomeScreen(
        selectedTab: currentTab,
        tabBuilder: (context, tab) => switch (tab) {
          HomeTab.books => FlowRouteScope(
            routeInformation: RouteInformation(uri: Uri(path: 'books')),
            isActive: currentTab == HomeTab.books,
            child: const BooksFlowCoordinator(),
          ),
          HomeTab.settings => FlowRouteScope(
            routeInformation: RouteInformation(uri: Uri(path: 'settings')),
            isActive: currentTab == HomeTab.settings,
            child: const SettingsScreen(),
          ),
        },
      ),
    );
  }
}
