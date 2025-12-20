import 'package:flutter/widgets.dart';

import 'flow_coordinator_mixin.dart';

/// Provides access to the nearest [FlowCoordinatorMixin] in the widget tree.
///
/// This sealed class cannot be instantiated or extended. It serves as a
/// namespace for the static [of] method, which screens use to find and
/// interact with their managing flow coordinator.
///
/// See also:
///
/// * [FlowCoordinatorMixin], which flow coordinators mix in to manage
///   navigation and routing.
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
