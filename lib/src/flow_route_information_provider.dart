import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';

abstract class FlowRouteInformationProvider {
  static FlowRouteInformationProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<
        FlowRouteInformationProviderScope>();
    if (scope == null) {
      throw FlutterError(
        '''
FlowRouteInformationProvider.of() called with a context that does not contain a FlowRouteInformationProviderScope.
Make sure the WidgetsApp/MaterialApp/CupertinoApp is set up with FlowCoordinatorRouter.
The context used was: $context
''',
      );
      // TODO: Consider using something like this:
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'StreamChat.of() called with a context that does not contain a '
          'StreamChat.',
        ),
        ErrorDescription(
          'No StreamChat ancestor could be found starting from the context '
          'that was passed to StreamChat.of(). This usually happens when the '
          'context used comes from the widget that creates the StreamChat '
          'itself.',
        ),
        ErrorHint(
          'To fix this, ensure that you are using a context that is a descendant '
          'of the StreamChat. You can use a Builder to get a new context that '
          'is under the StreamChat:\n\n'
          '  Builder(\n'
          '    builder: (context) {\n'
          '      final chatState = StreamChat.of(context);\n'
          '      ...\n'
          '    },\n'
          '  )',
        ),
        ErrorHint(
          'Alternatively, split your build method into smaller widgets so that '
          'you get a new BuildContext that is below the StreamChat in the '
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
