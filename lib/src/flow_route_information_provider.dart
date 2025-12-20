import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';

abstract class FlowRouteInformationProvider {
  static FlowRouteInformationProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        FlowRouteInformationProviderScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No FlowRouteInformationProviderScope found.'),
        ErrorHint(
          'Make sure the MaterialApp/CupertinoApp/WidgetsApp widget of your '
          'app is set up with a FlowCoordinatorRouter.',
        ),
        ...context.describeMissingAncestor(
          expectedAncestorType: FlowRouteInformationProviderScope,
        ),
      ]);
    }
    return scope.value;
  }

  /// The route information children flows can consume.
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable;
}

abstract class ChildFlowRouteInformationProvider
    extends FlowRouteInformationProvider {
  /// The route information that has been consumed by the flow.
  ValueListenable<RouteInformation?> get consumedValueListenable;
}

class FlowRouteInformationProviderScope extends InheritedWidget {
  const FlowRouteInformationProviderScope(
    this.value, {
    super.key,
    required super.child,
  });

  final FlowRouteInformationProvider value;

  @override
  bool updateShouldNotify(FlowRouteInformationProviderScope oldWidget) =>
      value != oldWidget.value;
}
