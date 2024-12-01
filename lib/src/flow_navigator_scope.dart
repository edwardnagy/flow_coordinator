import 'package:flutter/widgets.dart';

import 'flow_navigator.dart';

class FlowNavigatorScope extends InheritedWidget {
  const FlowNavigatorScope({
    super.key,
    required this.navigator,
    required super.child,
  });

  final FlowNavigator navigator;

  @override
  bool updateShouldNotify(FlowNavigatorScope oldWidget) {
    return navigator != oldWidget.navigator;
  }
}
