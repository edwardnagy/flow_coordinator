import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumable.dart';
import 'flow_back_button_dispatcher_builder.dart';
import 'flow_navigator.dart';
import 'flow_route_information_provider.dart';
import 'flow_router_delegate.dart';
import 'route_information_combiner.dart';

// Public APIs

export 'flow_navigator.dart' show FlowNavigator;
export 'route_information_combiner.dart' show RouteInformationCombiner;

/// A mixin that provides navigation and routing capabilities to flow
/// coordinators.
///
/// Flow coordinators organize screens into logical user flows and manage the
/// navigation rules between those screens. This mixin handles the integration
/// with Flutter's routing system and manages the communication between parent
/// and child flows.
///
/// ## Usage
///
/// To create a flow coordinator, create a [StatefulWidget] and mix
/// [FlowCoordinatorMixin] into its [State]:
///
/// ```dart
/// class MyFlowCoordinator extends StatefulWidget {
///   const MyFlowCoordinator({super.key});
///
///   @override
///   State<MyFlowCoordinator> createState() => _MyFlowCoordinatorState();
/// }
///
/// class _MyFlowCoordinatorState extends State<MyFlowCoordinator>
///     with FlowCoordinatorMixin {
///   @override
///   List<Page> get initialPages => [
///     MaterialPage(child: MyFirstScreen()),
///   ];
/// }
/// ```
///
/// ## Key Features
///
/// * **Navigation Management**: Use [flowNavigator] to push, pop, and manage
/// pages within the flow. The initial state of the flow is defined by 
/// overriding [initialPages].
///
/// * **Deep Linking**: Override [onNewRouteInformation] to handle deep links
/// from the parent flow or the platform.
///
/// * **Nested Flows**: Child flows can be integrated into the current flow as
/// any other screen, by wrapping them in a [Page] and adding them to the
/// navigation stack using [flowNavigator].
///
/// * **Combined Reporting of Route Information**: [routeInformationCombiner]
/// allows customization of  how route information from nested flows is combined
/// into the current flow before being sent to the parent flow or the platform.
///
/// * **Programmatic Navigation**: Use [setNewRouteInformation] to
/// programmatically set a new deep link for the flow.
mixin FlowCoordinatorMixin<T extends StatefulWidget> on State<T> {
  FlowRouteInformationProvider? _parentRouteInformationProvider;

  late final _routerDelegate = FlowRouterDelegate(
    initialPages: initialPages,
    contextDescriptionProvider: () => context
        .describeWidget('The flow coordinator being built was')
        .toString(),
  );

  late final _routeInformationProvider = _ChildFlowRouteInformationProvider();

  /// The initial list of pages for this flow.
  List<Page> get initialPages => [];

  /// The [FlowNavigator] used for navigation within this flow.
  @nonVirtual
  FlowNavigator get flowNavigator => _routerDelegate;

  /// The initial route information used when no route information is
  /// provided by the parent flow.
  RouteInformation? get initialRouteInformation => null;

  /// Defines how route information from nested flows is combined into the
  /// current flow.
  RouteInformationCombiner get routeInformationCombiner =>
      const DefaultRouteInformationCombiner();

  /// Handles incoming route information for this flow.
  ///
  /// The returned [RouteInformation], if non-null, will be forwarded to nested
  /// flows.
  ///
  /// This method allows new pages to be pushed or set using [flowNavigator].
  ///
  /// The [routeInformation] parameter contains the new route information that
  /// may come from the parent flow, the system, or via
  /// [setNewRouteInformation].
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously to avoid waiting for the next microtask to schedule the
  /// build.
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    return SynchronousFuture(null);
  }

  /// Sets new route information for this flow.
  ///
  /// See [onNewRouteInformation] for details on how this information is
  /// processed.
  @nonVirtual
  void setNewRouteInformation(RouteInformation routeInformation) {
    _routeInformationProvider.consumedValueNotifier.value = routeInformation;
    onNewRouteInformation(routeInformation).then((childRouteInformation) {
      if (childRouteInformation != null) {
        _routeInformationProvider.childValueNotifier.value =
            Consumable(childRouteInformation);
      }
    });
  }

  void _onValueReceivedFromParent() {
    assert(_parentRouteInformationProvider != null);
    final value = _parentRouteInformationProvider!.childValueListenable.value;
    final routeInformation = value?.consumeOrNull();
    if (routeInformation != null) {
      setNewRouteInformation(routeInformation);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update the parent navigator.
    final parentNavigator = FlowNavigator.maybeOf(context, listen: true);
    _routerDelegate.setParentFlowNavigator(parentNavigator);

    // Update the parent route information provider.
    final parentRouteInformationProvider =
        FlowRouteInformationProvider.of(context);
    if (parentRouteInformationProvider != _parentRouteInformationProvider) {
      _parentRouteInformationProvider?.childValueListenable
          .removeListener(_onValueReceivedFromParent);

      _parentRouteInformationProvider = parentRouteInformationProvider;

      final routeInformation = parentRouteInformationProvider
          .childValueListenable.value
          ?.consumeOrNull();
      if (routeInformation != null) {
        setNewRouteInformation(routeInformation);
      }
      parentRouteInformationProvider.childValueListenable
          .addListener(_onValueReceivedFromParent);
    }

    // Set the initial route information if other route information was not
    // provided by the parent.
    final initialRouteInformation = this.initialRouteInformation;
    if (_routeInformationProvider.consumedValueListenable.value == null &&
        initialRouteInformation != null) {
      setNewRouteInformation(initialRouteInformation);
    }
  }

  @override
  void dispose() {
    _parentRouteInformationProvider?.childValueListenable
        .removeListener(_onValueReceivedFromParent);
    _routeInformationProvider.dispose();
    _routerDelegate.dispose();
    super.dispose();
  }

  /// Builds the router widget for this flow.
  @nonVirtual
  Widget flowRouter(BuildContext context) {
    return FlowBackButtonDispatcherBuilder(
      builder: (context, backButtonDispatcher) {
        return FlowRouteInformationProviderScope(
          _routeInformationProvider,
          child: RouteInformationCombinerScope(
            routeInformationCombiner,
            child: FlowNavigatorScope(
              flowNavigator: _routerDelegate,
              child: Router(
                routerDelegate: _routerDelegate,
                backButtonDispatcher: backButtonDispatcher,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return flowRouter(context);
  }
}

class _ChildFlowRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      consumedValueNotifier;

  final consumedValueNotifier = ValueNotifier<RouteInformation?>(null);

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      childValueNotifier;

  final childValueNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);

  void dispose() {
    consumedValueNotifier.dispose();
    childValueNotifier.dispose();
  }
}
