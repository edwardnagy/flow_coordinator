import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';
import 'flow_route_information_provider.dart';

typedef RouteInformationPredicate = bool Function(
  RouteInformation routeInformation,
);

/// A widget that forwards route updates to nested flows only when the parent
/// route matches a specified condition.
///
/// The [FlowRouteInformationProvider] inserted in the widget tree maintains the
/// same route information as the parent, but it manages child-specific route
/// updates separately based on the [shouldForwardChildUpdates] predicate.
class ChildRouteInformationFilter extends StatefulWidget {
  /// Creates a [ChildRouteInformationFilter].
  ///
  /// Wraps [child] with a new [FlowRouteInformationProvider] that
  /// forwards route updates based on [shouldForwardChildUpdates].
  const ChildRouteInformationFilter({
    super.key,
    required this.shouldForwardChildUpdates,
    required this.child,
  });

  /// Creates a [ChildRouteInformationFilter] that forwards child route updates
  /// only if the child route information matches the specified [pattern].
  /// See [RouteInformationMatcher.matchesUrlPattern] for details.
  ChildRouteInformationFilter.pattern({
    Key? key,
    required RouteInformation pattern,
    bool Function(Object? state, Object? patternState)? stateMatcher,
    required Widget child,
  }) : this(
          key: key,
          shouldForwardChildUpdates: (routeInformation) => routeInformation
              .matchesUrlPattern(pattern, stateMatcher: stateMatcher),
          child: child,
        );

  /// Whether the most recently consumed route information from the parent flow
  /// matches the condition to forward child route information updates to the
  /// child flow.
  final RouteInformationPredicate shouldForwardChildUpdates;

  /// The widget subtree that receives filtered route updates.
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
        shouldForwardChildUpdates: widget.shouldForwardChildUpdates,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ChildRouteInformationFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.shouldForwardChildUpdates !=
        widget.shouldForwardChildUpdates) {
      // Re-evaluate the condition and update child route information if needed.
      _filterProvider!.setForwardingCriteria(widget.shouldForwardChildUpdates);
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

class _FilterFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  _FilterFlowRouteInformationProvider({
    required this.parentProvider,
    required this.shouldForwardChildUpdates,
  })  : _consumedValueNotifier = ValueNotifier(null),
        _childValueNotifier = ValueNotifier(null) {
    _updateValue();
    parentProvider.consumedValueListenable.addListener(_updateValue);
    _updateChildValueIfParentMatchesCriteria();
    parentProvider.childValueListenable
        .addListener(_updateChildValueIfParentMatchesCriteria);
  }

  final ChildFlowRouteInformationProvider parentProvider;
  final ValueNotifier<RouteInformation?> _consumedValueNotifier;
  final ValueNotifier<Consumable<RouteInformation>?> _childValueNotifier;

  RouteInformationPredicate shouldForwardChildUpdates;

  void setForwardingCriteria(RouteInformationPredicate value) {
    shouldForwardChildUpdates = value;
    // Re-evaluate the condition and update child route information if needed.
    _updateChildValueIfParentMatchesCriteria();
  }

  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      _consumedValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      _childValueNotifier;

  void _updateValue() {
    _consumedValueNotifier.value = parentProvider.consumedValueListenable.value;
  }

  void _updateChildValueIfParentMatchesCriteria() {
    final parentConsumedValue = parentProvider.consumedValueListenable.value;
    if (parentConsumedValue != null &&
        shouldForwardChildUpdates(parentConsumedValue)) {
      final routeInformation =
          parentProvider.childValueListenable.value?.consumeOrNull();
      if (routeInformation != null) {
        _childValueNotifier.value = Consumable(routeInformation);
      }
    }
  }

  void dispose() {
    parentProvider.consumedValueListenable.removeListener(_updateValue);
    parentProvider.childValueListenable
        .removeListener(_updateChildValueIfParentMatchesCriteria);
    _consumedValueNotifier.dispose();
    _childValueNotifier.dispose();
  }
}

extension RouteInformationMatcher on RouteInformation {
  /// Determines whether this route matches the given [pattern].
  ///
  /// A match occurs if:
  /// - The path segments in [pattern] appear in this URI in the same order,
  /// starting from the beginning of the path.
  /// - All query parameters in [pattern] are present and match those in this
  /// URI.
  /// - The fragment in [pattern] is either empty or matches this URI's
  /// fragment.
  /// - The state matches the pattern’s state, using [stateMatcher] if provided.
  /// If omitted, states are considered equal if they are identical, or if
  /// the pattern's state is `null`.
  bool matchesUrlPattern(
    RouteInformation pattern, {
    bool Function(Object? state, Object? patternState)? stateMatcher,
  }) {
    final isPathMatching =
        pattern.uri.pathSegments.length <= uri.pathSegments.length &&
            pattern.uri.pathSegments.asMap().entries.every(
                  (patternEntry) =>
                      patternEntry.value == uri.pathSegments[patternEntry.key],
                );
    final isQueryMatching = pattern.uri.queryParameters.entries.every(
      (patternEntry) =>
          uri.queryParameters[patternEntry.key] == patternEntry.value,
    );
    final isFragmentMatching =
        pattern.uri.fragment.isEmpty || pattern.uri.fragment == uri.fragment;
    final isStateMatching = stateMatcher?.call(state, pattern.state) ??
        (pattern.state == null || state == pattern.state);

    return isPathMatching &&
        isQueryMatching &&
        isFragmentMatching &&
        isStateMatching;
  }
}
