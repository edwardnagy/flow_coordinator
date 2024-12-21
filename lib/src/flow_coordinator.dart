import 'package:flutter/widgets.dart';

final class FlowCoordinator {
  /// Utility method to find the nearest [State] of type [T] in the widget tree.
  ///
  /// Throws a [FlutterError] if no [State] is found.
  static T of<T extends State>(
    BuildContext context,
  ) {
    final state = maybeOf<T>(context);
    if (state == null) {
      throw FlutterError('Could not find a FlowCoordinatorState of type $T.');
    }
    return state;
  }

  /// Utility method to find the nearest [State] of type [T] in the widget tree,
  /// or null if no [State] is found.
  static T? maybeOf<T extends State>(BuildContext context) {
    return context.findAncestorStateOfType<T>();
  }
}
