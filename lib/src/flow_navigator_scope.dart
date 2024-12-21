import 'package:flutter/widgets.dart';

import 'flow_navigator.dart';

class FlowNavigatorScope extends InheritedWidget {
  const FlowNavigatorScope({
    super.key,
    required this.flowNavigator,
    required super.child,
  });

  final FlowNavigator flowNavigator;

  @override
  bool updateShouldNotify(FlowNavigatorScope oldWidget) {
    return flowNavigator != oldWidget.flowNavigator;
  }
}
