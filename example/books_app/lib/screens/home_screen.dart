import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';

abstract interface class HomeScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onTabSelected(HomeTab tab);

  void resetNavigationStackForTab(HomeTab tab);
}

enum HomeTab {
  books,
  settings,
}

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
    final currentIndex = tabs.indexOf(selectedTab);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: tabs
            .map(
              (tab) => Builder(
                builder: (context) => tabBuilder(context, tab),
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == tabs.indexOf(selectedTab)) {
            FlowCoordinator.of<HomeScreenListener>(context)
                .resetNavigationStackForTab(selectedTab);
          } else {
            FlowCoordinator.of<HomeScreenListener>(context)
                .onTabSelected(tabs[index]);
          }
        },
        items: tabs
            .map((tab) => switch (tab) {
                  HomeTab.books => const BottomNavigationBarItem(
                      icon: Icon(Icons.book),
                      label: 'Books',
                    ),
                  HomeTab.settings => const BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                })
            .toList(),
      ),
    );
  }
}
