import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';
import 'flow_route_information_provider.dart';

typedef RouteInformationPredicate = bool Function(
  RouteInformation routeInformation,
);

/// A widget that filters route information updates from a parent
/// [ChildFlowRouteInformationProvider] based on the provided
/// [parentValueMatcher].
class ChildRouteInformationFilter extends StatefulWidget {
  const ChildRouteInformationFilter({
    super.key,
    required this.parentValueMatcher,
    required this.child,
  });

  /// A predicate that determines whether child route information updates
  /// should be forwarded based on the parent's consumed route information.
  ///
  /// If `null`, all updates from the parent are forwarded to the child.
  final RouteInformationPredicate? parentValueMatcher;
  final Widget child;

  @override
  State<ChildRouteInformationFilter> createState() =>
      _ChildRouteInformationFilterState();
}

class _ChildRouteInformationFilterState
    extends State<ChildRouteInformationFilter> {
  ChildFlowRouteInformationProvider? _parentProvider;
  _FilterFlowRouteInformationProvider? _filterProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final parentProvider = FlowRouteInformationProvider.of(context);
    if (parentProvider != _parentProvider) {
      _filterProvider?.dispose();

      assert(
        parentProvider is ChildFlowRouteInformationProvider,
        'The parent FlowRouteInformationProvider must be a '
        'ChildFlowRouteInformationProvider to enable route filtering.',
      );
      _parentProvider = parentProvider as ChildFlowRouteInformationProvider;

      _filterProvider = _FilterFlowRouteInformationProvider(
        parentProvider: parentProvider,
        parentValueMatcher: widget.parentValueMatcher,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ChildRouteInformationFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.parentValueMatcher != widget.parentValueMatcher) {
      // Re-evaluate the condition and update child route information if needed.
      _filterProvider!.setParentValueMatcher(widget.parentValueMatcher);
    }
  }

  @override
  void dispose() {
    _filterProvider!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowRouteInformationProviderScope(
      _filterProvider!,
      child: widget.child,
    );
  }
}

/// A provider that filters route information updates from a parent provider.
///
/// It does the following:
/// - Copies the consumed value from the parent provider.
/// - Copies the consumable child value to its own notifier only if the parent's
/// consumed value matches the specified [parentValueMatcher].
class _FilterFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  _FilterFlowRouteInformationProvider({
    required this.parentProvider,
    required this.parentValueMatcher,
  })  : _consumedValueNotifier = ValueNotifier(null),
        _childValueNotifier = ValueNotifier(null) {
    _copyConsumedParentValue();
    parentProvider.consumedValueListenable
        .addListener(_copyConsumedParentValue);

    _copyChildValueIfParentValueMatches();
    parentProvider.childValueListenable.addListener(
      _copyChildValueIfParentValueMatches,
    );
  }

  final ChildFlowRouteInformationProvider parentProvider;
  final ValueNotifier<RouteInformation?> _consumedValueNotifier;
  final ValueNotifier<Consumable<RouteInformation>?> _childValueNotifier;

  RouteInformationPredicate? parentValueMatcher;

  void setParentValueMatcher(RouteInformationPredicate? value) {
    parentValueMatcher = value;
    // Re-evaluate the condition and update child route information if needed.
    _copyChildValueIfParentValueMatches();
  }

  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      _consumedValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      _childValueNotifier;

  void _copyConsumedParentValue() {
    _consumedValueNotifier.value = parentProvider.consumedValueListenable.value;
  }

  void _copyChildValueIfParentValueMatches() {
    final parentConsumedValue = parentProvider.consumedValueListenable.value;
    final parentValueMatcher = this.parentValueMatcher;

    var shouldCopyChildValue = parentValueMatcher == null ||
        (parentConsumedValue != null &&
            parentValueMatcher(parentConsumedValue));

    if (shouldCopyChildValue) {
      final routeInformation =
          parentProvider.childValueListenable.value?.consumeOrNull();
      if (routeInformation != null) {
        _childValueNotifier.value = Consumable(routeInformation);
      }
    }
  }

  void dispose() {
    parentProvider.consumedValueListenable
        .removeListener(_copyConsumedParentValue);
    parentProvider.childValueListenable
        .removeListener(_copyChildValueIfParentValueMatches);
    _consumedValueNotifier.dispose();
    _childValueNotifier.dispose();
  }
}
