import 'dart:async';

import 'package:flutter/widgets.dart';

import 'consumable_value.dart';
import 'flow_route_information_provider.dart';

/// A widget that filters and forwards route updates to nested flows
/// when the parent route matches a specified condition.
///
/// The [FlowRouteInformationProvider] inserted in the widget tree
/// maintains the same route information as the parent, but it
/// manages child-specific route updates separately.
class ChildRouteInformationFilter extends StatefulWidget {
  /// Creates a [ChildRouteInformationFilter].
  ///
  /// Wraps [child] with a new [FlowRouteInformationProvider] that
  /// forwards route updates based on [isMatchingRouteInformation].
  const ChildRouteInformationFilter({
    super.key,
    required this.child,
    required this.isMatchingRouteInformation,
  });

  /// The widget subtree that receives filtered route updates.
  final Widget child;

  /// Determines whether the current route information matches the
  /// condition to forward updates to the child.
  final bool Function(RouteInformation routeInformation)
      isMatchingRouteInformation;

  @override
  State<ChildRouteInformationFilter> createState() =>
      _ChildRouteInformationFilterState();
}

class _ChildRouteInformationFilterState
    extends State<ChildRouteInformationFilter> {
  late final _routeInformationProvider = ChildFlowRouteInformationProvider(
    initialValue: RouteInformation(uri: Uri()),
  );

  FlowRouteInformationProvider? _parentProvider;
  StreamSubscription? _childValueSubscription;

  RouteInformation get _parentValue {
    assert(_parentProvider != null);
    return _parentProvider!.value;
  }

  /// Filters and forwards the child's route information when the
  /// parent route matches [widget.isCurrentMatching].
  void _filterChildValue(
    ConsumableValue<RouteInformation> childConsumableValue,
  ) {
    if (widget.isMatchingRouteInformation(_parentValue)) {
      final routeInformation = childConsumableValue.getAndConsumeOrNull();
      if (routeInformation != null) {
        _routeInformationProvider.setChildValue(routeInformation);
      }
    }
  }

  /// Copies the parent route information into this widget’s provider.
  void _copyParentValue() {
    _routeInformationProvider.value = _parentValue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Remove previous listeners.
    _parentProvider?.removeListener(_copyParentValue);
    _childValueSubscription?.cancel();

    final parentProvider = FlowRouteInformationProvider.maybeOf(context);
    _parentProvider = parentProvider;

    if (parentProvider != null) {
      // Sync with the new parent provider.
      _copyParentValue();
      parentProvider.addListener(_copyParentValue);

      // Handle child route updates.
      if (parentProvider.childConsumableValue
          case final childConsumableValue?) {
        _filterChildValue(childConsumableValue);
      }
      _childValueSubscription =
          parentProvider.childConsumableValueStream.listen(_filterChildValue);
    }
  }

  @override
  void didUpdateWidget(covariant ChildRouteInformationFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isMatchingRouteInformation !=
        widget.isMatchingRouteInformation) {
      // Re-evaluate the condition and update child route info accordingly.
      if (_parentProvider?.childConsumableValue
          case final childConsumableValue?) {
        _filterChildValue(childConsumableValue);
      }
    }
  }

  @override
  void dispose() {
    _childValueSubscription?.cancel();
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
