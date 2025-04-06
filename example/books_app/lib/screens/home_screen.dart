import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

abstract interface class HomeScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onTabSelected(HomeTab tab);

  void resetNavigationStackForTab(HomeTab tab);
}

enum HomeTab {
  books,
  search,
  settings,
}

const _keepTabStates = !kIsWeb;

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.selectedTab,
    required this.tabBuilder,
  });

  final HomeTab? selectedTab;
  final Widget Function(BuildContext context, HomeTab tab) tabBuilder;

  @override
  Widget build(BuildContext context) {
    const tabs = HomeTab.values;
    final selectedTab = this.selectedTab ?? tabs.first;

    return Scaffold(
      // TODO: Replace AdaptiveScaffold because it will be discontinued: https://github.com/flutter/flutter/issues/162965
      body: AdaptiveScaffold(
        useDrawer: kIsWeb,
        transitionDuration: const Duration(milliseconds: 300),
        selectedIndex: tabs.indexOf(selectedTab),
        onSelectedIndexChange: (index) {
          if (index == tabs.indexOf(selectedTab)) {
            FlowCoordinator.of<HomeScreenListener>(context)
                .resetNavigationStackForTab(selectedTab);
          } else {
            FlowCoordinator.of<HomeScreenListener>(context)
                .onTabSelected(tabs[index]);
          }
        },
        destinations: tabs
            .map((tab) => switch (tab) {
                  HomeTab.books => const NavigationDestination(
                      icon: Icon(Icons.book),
                      label: 'Books',
                    ),
                  HomeTab.search => const NavigationDestination(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                  HomeTab.settings => const NavigationDestination(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                })
            .toList(),
        body: (context) => _keepTabStates
            ? IndexedStack(
                index: tabs.indexOf(selectedTab),
                children: tabs.map((tab) => tabBuilder(context, tab)).toList(),
              )
            : tabBuilder(context, selectedTab),
      ),
    );
  }
}
