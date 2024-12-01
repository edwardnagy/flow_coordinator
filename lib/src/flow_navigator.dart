import 'package:flutter/widgets.dart';

import 'flow_navigator_scope.dart';

// TODO: Add documentation
abstract interface class FlowNavigator {
  /// Returns the nearest [FlowNavigator] for the given [context].
  ///
  /// Throws a [FlutterError] if none is found. Use [maybeOf] to return null
  /// instead.
  static FlowNavigator of(BuildContext context) {
    final navigatorScope =
        context.getInheritedWidgetOfExactType<FlowNavigatorScope>();
    if (navigatorScope == null) {
      throw FlutterError(
        '''
FlowNavigator.of() called with a context that does not contain a FlowNavigatorScope.

This happens if no NavigatorFlowCoordinatorState is found above this widget in the widget tree.

The context used was: $context
''',
      );
    }
    return navigatorScope.navigator;
  }

  /// Returns the nearest [FlowNavigator] in the given [context], or null if no
  /// [FlowNavigator] is found.
  static FlowNavigator? maybeOf(BuildContext context) {
    final navigatorScope =
        context.getInheritedWidgetOfExactType<FlowNavigatorScope>();
    return navigatorScope?.navigator;
  }

  /// Pushes the given [page] onto the navigator.
  void push(Page page);

  /// Sets the navigator's history to the given [pages].
  void setPages(List<Page> pages);

  /// Replaces the current page with the given [page].
  void replaceCurrentPage(Page page);

  /// Returns whether this navigator or its parent can pop.
  bool canPop();

  /// Same as [Navigator.canPop]. Only considers this navigator.
  bool canPopInternally();

  /// Attempts to pop this navigator, and if unsuccessful, delegates to the
  /// parent navigator's [maybePop].
  Future<bool> maybePop<T extends Object?>([T? result]);

  /// Same as [Navigator.pop]. Only considers this navigator.
  Future<bool> maybePopInternally<T extends Object?>([T? result]);

  /// Calls [popInternally] and if false, calls [pop] on the parent navigator.
  void pop<T extends Object?>([T? result]);

  /// Same as [Navigator.pop]. Only considers this navigator.
  void popInternally<T extends Object?>([T? result]);
}
