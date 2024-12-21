import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../screen/book_creation_screen.dart';
import '../../screen/main_screen.dart';
import '../../shared/dialog_page.dart';
import '../books/books_flow_coordinator.dart';

part 'authenticated_flow_route_information_parser.dart';
part 'authenticated_flow_state.dart';

class AuthenticatedFlowCoordinator extends StatefulWidget {
  const AuthenticatedFlowCoordinator({super.key});

  @override
  State<AuthenticatedFlowCoordinator> createState() =>
      _AuthenticatedFlowCoordinatorState();
}

final class _AuthenticatedFlowCoordinatorState extends FlowCoordinatorState<
        AuthenticatedFlowCoordinator, AuthenticatedFlowState>
    implements
        MainScreenListener<AuthenticatedFlowCoordinator>,
        BooksFlowListener<AuthenticatedFlowCoordinator> {
  @override
  final RouteInformationParser<FlowRoute<AuthenticatedFlowState>>?
      routeInformationParser = AuthenticatedFlowRouteInformationParser();

  @override
  Future<void> setNewState(AuthenticatedFlowState flowState) {
    flowNavigator.setPages([
      _Pages.mainPage(currentTab: flowState.selectedTab),
      if (flowState.isCreatingBook) _Pages.bookCreationPage(),
    ]);

    return SynchronousFuture(null);
  }

  @override
  void onTabSelected(MainTab tab) {
    final newState = AuthenticatedFlowState(selectedTab: tab);
    setNewState(newState);
  }

  @override
  void onCreateBook() {
    const newState = AuthenticatedFlowState(isCreatingBook: true);
    setNewState(newState);
  }
}

class _Pages {
  static Page mainPage({
    required MainTab currentTab,
  }) =>
      FlowStatePageWrapper(
        flowState: AuthenticatedFlowState(selectedTab: currentTab),
        page: MaterialPage(
          key: const ValueKey('MainTabsScaffold'),
          child: MainScreen(
            selectedTab: currentTab,
            tabBuilder: (context, tab) => switch (tab) {
              MainTab.books => const BooksFlowCoordinator(),
              MainTab.settings => const Placeholder(),
            },
          ),
        ),
      );

  static Page bookCreationPage() => const FlowStatePageWrapper(
        flowState: AuthenticatedFlowState(isCreatingBook: true),
        page: DialogPage(
          key: ValueKey('bookCreationPage'),
          child: BookCreationScreen(),
        ),
      );
}
