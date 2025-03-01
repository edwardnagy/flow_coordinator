import 'dart:async';

import 'package:flutter/widgets.dart';

import 'consumable_value.dart';
import 'flow_route_information_provider.dart';

/// A widget that filters and forwards route information to nested flows
/// based on a [filter] function.
///
/// This widget listens to a [FlowRouteInformationProvider] in the parent
/// and propagates its route information to a child [FlowRouteInformationProvider].
/// The child receives updates only if [filter] returns `true` for the parent route.
///
/// The provided [FlowRouteInformationProvider] in the widget tree maintains
/// the same route information as the parent, but it manages child-specific
/// route updates separately.
class ParentRouteInformationFilter extends StatefulWidget {
  /// Creates a [ParentRouteInformationFilter].
  ///
  /// The [child] is wrapped with a new [FlowRouteInformationProvider] that
  /// forwards route updates based on [filter].
  const ParentRouteInformationFilter({
    super.key,
    required this.child,
    required this.filter,
  });

  final Widget child;

  /// Determines whether the child route information should be forwarded
  /// based on the parent route.
  final bool Function(RouteInformation parentRouteInformation) filter;

  @override
  State<ParentRouteInformationFilter> createState() =>
      _ParentRouteInformationFilterState();
}

class _ParentRouteInformationFilterState
    extends State<ParentRouteInformationFilter> {
  late final _routeInformationProvider = ChildFlowRouteInformationProvider(
    initialValue: RouteInformation(uri: Uri()),
  );

  FlowRouteInformationProvider? _parentProvider;
  StreamSubscription? _valueFromParentSubscription;

  void _onChildValueChanged(
    ConsumableValue<RouteInformation> childConsumableValue,
  ) {
    assert(_parentProvider != null);
    if (widget.filter(_parentProvider!.value)) {
      final routeInformation = childConsumableValue.getAndConsumeOrNull();
      if (routeInformation != null) {
        _routeInformationProvider.setChildValue(routeInformation);
      }
    }
  }

  void _onParentValueChanged() {
    assert(_parentProvider != null);
    _routeInformationProvider.value = _parentProvider!.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Remove previous listeners.
    _parentProvider?.removeListener(_onParentValueChanged);
    _valueFromParentSubscription?.cancel();

    final newParentProvider = FlowRouteInformationProvider.maybeOf(context);
    _parentProvider = newParentProvider;

    if (newParentProvider != null) {
      // Sync with the new parent provider.
      _onParentValueChanged();
      newParentProvider.addListener(_onParentValueChanged);

      // Handle child route updates.
      if (newParentProvider.childConsumableValue
          case final childConsumableValue?) {
        _onChildValueChanged(childConsumableValue);
      }
      _valueFromParentSubscription = newParentProvider
          .childConsumableValueStream
          .listen(_onChildValueChanged);
    }
  }

  @override
  void dispose() {
    _valueFromParentSubscription?.cancel();
    _routeInformationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowRouteInformationProviderScope(
      _routeInformationProvider,
      child: widget.child,
    );
  }
}
