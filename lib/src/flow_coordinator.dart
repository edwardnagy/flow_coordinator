import 'package:flutter/widgets.dart';

import 'flow_coordinator_mixin.dart';

sealed class FlowCoordinator {
  const FlowCoordinator._();

  /// Finds the nearest [FlowCoordinatorMixin] of type [T] in the widget tree.
  ///
  /// Throws a [FlutterError] if no such ancestor is found.
  static T of<T extends FlowCoordinatorMixin>(BuildContext context) {
    final state = context.findAncestorStateOfType<T>();
    if (state == null) {
      throw FlutterError('Could not find a FlowCoordinatorMixin of type $T.');
    }
    return state;
  }
}
