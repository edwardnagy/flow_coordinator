import 'package:books_app/screen/book_creation_screen.dart';
import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screen/home_screen.dart';
import '../screen/not_found_screen.dart';
import '../shared/dialog_page.dart';
import 'books_flow_coordinator.dart';

class HomeFlowCoordinator extends StatefulWidget {
  const HomeFlowCoordinator({super.key});

  @override
  State<HomeFlowCoordinator> createState() => _HomeFlowCoordinatorState();
}

final class _HomeFlowCoordinatorState
    extends FlowCoordinatorState<HomeFlowCoordinator>
    implements
        HomeScreenListener<HomeFlowCoordinator>,
        BooksFlowListener<HomeFlowCoordinator> {
  @override
  Future<RouteInformation?> setNewRoute(RouteInformation routeInformation) {
    // Parse the route information.
    final homeTab = switch (routeInformation.uri.pathSegments.firstOrNull) {
      null || '' || 'books' => HomeTab.books,
      'search' => HomeTab.search,
      'settings' => HomeTab.settings,
      _ => null,
    };
    final isCreatingBook =
        routeInformation.uri.pathSegments.firstOrNull == 'create-book';

    // Set up the navigation stack.
    flowNavigator.setPages([
      _Pages.homePage(currentTab: homeTab),
      if (isCreatingBook)
        _Pages.bookCreationPage()
      else if (homeTab == null)
        _Pages.notFoundPage(),
    ]);

    // Return the route information for the nested flows.
    final childRouteInformation = RouteInformation(
      uri: Uri(
        pathSegments: routeInformation.uri.pathSegments.skip(1),
        queryParameters: routeInformation.uri.queryParameters.isEmpty
            ? null
            : routeInformation.uri.queryParameters,
      ),
      state: routeInformation.state,
    );
    return SynchronousFuture(childRouteInformation);
  }

  @override
  void onTabSelected(HomeTab tab) {
    flowNavigator.setPages([
      _Pages.homePage(currentTab: tab),
    ]);
  }

  @override
  void onCreateBook() {
    flowNavigator.push(_Pages.bookCreationPage());
  }
}

class _Pages {
  static Page notFoundPage() => const MaterialPage(
        key: ValueKey('notFoundPage'),
        child: NotFoundScreen(),
      );

  static Page homePage({
    required HomeTab? currentTab,
  }) =>
      MaterialPage(
        key: const ValueKey('homePage'),
        child: RouteInformationScope(
          routeInformation: RouteInformation(
            uri: Uri(
              path: switch (currentTab) {
                HomeTab.books => 'books',
                HomeTab.search => 'search',
                HomeTab.settings => 'settings',
                _ => '',
              },
            ),
          ),
          child: HomeScreen(
            selectedTab: currentTab,
            tabBuilder: (context, tab) => switch (tab) {
              HomeTab.books => const BooksFlowCoordinator(),
              HomeTab.search => const Placeholder(),
              HomeTab.settings => const Placeholder(),
            },
          ),
        ),
      );

  static Page bookCreationPage() => DialogPage(
        key: const ValueKey('bookCreationPage'),
        child: RouteInformationScope(
          routeInformation: RouteInformation(
            uri: Uri(path: 'create-book'),
          ),
          child: const BookCreationScreen(),
        ),
      );
}
