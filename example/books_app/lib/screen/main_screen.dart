import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

abstract interface class MainScreenListener<T extends StatefulWidget>
    extends State<T> {
  void onTabSelected(MainTab tab);
}

enum MainTab {
  books,
  settings,
}

class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
    this.selectedTab,
    required this.tabBuilder,
  });

  final MainTab? selectedTab;
  final Widget Function(BuildContext context, MainTab tab) tabBuilder;

  @override
  Widget build(BuildContext context) {
    const tabs = MainTab.values;
    final selectedTab = this.selectedTab ?? tabs.first;

    return AdaptiveScaffold(
      useDrawer: kIsWeb,
      transitionDuration: const Duration(milliseconds: 300),
      selectedIndex: tabs.indexOf(selectedTab),
      onSelectedIndexChange: (index) {
        FlowCoordinator.of<MainScreenListener>(context)
            .onTabSelected(tabs[index]);
      },
      destinations: tabs
          .map((tab) => switch (tab) {
                MainTab.books => const NavigationDestination(
                    icon: Icon(Icons.book),
                    label: 'Books',
                  ),
                MainTab.settings => const NavigationDestination(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
              })
          .toList(),
      body: (context) => tabBuilder(context, selectedTab),
    );
  }
}
