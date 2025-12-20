import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';

abstract class FlowRouteInformationProvider {
  static FlowRouteInformationProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        FlowRouteInformationProviderScope>();
    if (scope == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'FlowRouteInformationProvider.of() called with a context that does not contain a '
          'FlowRouteInformationProviderScope.',
        ),
        ErrorDescription(
          'No FlowRouteInformationProviderScope ancestor could be found starting from the context '
          'that was passed to FlowRouteInformationProvider.of(). This usually happens when the '
          'context used comes from a widget that is not a descendant of a FlowCoordinator.',
        ),
        ErrorHint(
          'Make sure the WidgetsApp/MaterialApp/CupertinoApp is set up with FlowCoordinatorRouter, '
          'and that the widget calling FlowRouteInformationProvider.of() is within the widget tree '
          'of a FlowCoordinator.',
        ),
        ErrorHint(
          'If you are trying to call FlowRouteInformationProvider.of() from within '
          'a FlowCoordinator\'s build method, use a Builder widget to get a context '
          'that is a child of the FlowCoordinator:\n\n'
          '  @override\n'
          '  Widget build(BuildContext context) {\n'
          '    return Builder(\n'
          '      builder: (context) {\n'
          '        final provider = FlowRouteInformationProvider.of(context);\n'
          '        ...\n'
          '      },\n'
          '    );\n'
          '  }',
        ),
        ErrorHint(
          'Alternatively, split your build method into smaller widgets so that '
          'you get a new BuildContext that is below the FlowCoordinator in the '
          'widget tree.',
        ),
        context.describeElement('The context used was'),
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
