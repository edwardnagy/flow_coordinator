import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_coordinator.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinatorMixin', () {
    testWidgets(
      'assertion error includes context description when initialPages is empty',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => const _EmptyFlowCoordinator(),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        final error = tester.takeException();
        expect(error, isA<AssertionError>());
        expect(
          error.toString(),
          contains(
            'The flow coordinator being built was: _EmptyFlowCoordinator',
          ),
        );
      },
    );

    testWidgets(
      'flowNavigator returns a usable FlowNavigator',
      (tester) async {
        FlowNavigator? capturedNavigator;

        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _FlowNavigatorAccessFlowCoordinator(
            onBuilt: (navigator) => capturedNavigator = navigator,
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        expect(capturedNavigator, isA<FlowNavigator>());

        // Verify the navigator is functional by pushing a page.
        capturedNavigator!.push(
          const MaterialPage(
            key: ValueKey('pushed'),
            child: Text('Pushed Page'),
          ),
        );
        await tester.pump();

        expect(find.text('Pushed Page'), findsOneWidget);
      },
    );

    testWidgets(
      'receives route information pushed by parent after initial build',
      (tester) async {
        final receivedRoutes = <RouteInformation>[];
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _RouteTrackingFlowCoordinator(
            onRouteReceived: receivedRoutes.add,
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        // Clear any routes received during the initial build.
        receivedRoutes.clear();

        // Simulate a subsequent deep link from the platform.
        await router.routerDelegate.setNewRoutePath(
          RouteInformation(uri: Uri.parse('/deep-link')),
        );

        expect(receivedRoutes, hasLength(1));
        expect(receivedRoutes.first.uri, Uri.parse('/deep-link'));
      },
    );

    testWidgets(
      'removes listener from old parent and attaches to new parent '
      'when provider changes',
      (tester) async {
        final receivedRoutes = <RouteInformation>[];
        final providerA = _TestFlowRouteInformationProvider();
        final providerB = _TestFlowRouteInformationProvider();
        final activeProvider =
            ValueNotifier<_TestFlowRouteInformationProvider>(providerA);
        addTearDown(activeProvider.dispose);

        final router = FlowCoordinatorRouter(
          homeBuilder: (_) =>
              ValueListenableBuilder<_TestFlowRouteInformationProvider>(
            valueListenable: activeProvider,
            child: _RouteTrackingFlowCoordinator(
              onRouteReceived: receivedRoutes.add,
            ),
            builder: (context, provider, child) {
              return FlowRouteInformationProviderScope(
                provider,
                child: child!,
              );
            },
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        // Switch to providerB.
        activeProvider.value = providerB;
        await tester.pump();

        // Push to the old provider — should NOT trigger the callback.
        providerA.childValueNotifier.value =
            Consumable(RouteInformation(uri: Uri.parse('/from-old')));
        await tester.pump();
        expect(receivedRoutes, isEmpty);

        // Push to the new provider — should trigger the callback.
        providerB.childValueNotifier.value =
            Consumable(RouteInformation(uri: Uri.parse('/from-new')));
        await tester.pump();
        expect(receivedRoutes, hasLength(1));
        expect(receivedRoutes.first.uri, Uri.parse('/from-new'));
      },
    );

    testWidgets(
      'applies initialRouteInformation when no custom route was consumed',
      (tester) async {
        final receivedRoutes = <RouteInformation>[];

        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _InitialRouteFlowCoordinator(
            initialRouteInfo: RouteInformation(uri: Uri.parse('/home')),
            onRouteReceived: receivedRoutes.add,
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );

        expect(receivedRoutes, hasLength(1));
        expect(receivedRoutes.first.uri, Uri.parse('/home'));
      },
    );
  });
}


class _EmptyFlowCoordinator extends StatefulWidget {
  const _EmptyFlowCoordinator();

  @override
  State<_EmptyFlowCoordinator> createState() => _EmptyFlowCoordinatorState();
}

class _EmptyFlowCoordinatorState extends State<_EmptyFlowCoordinator>
    with FlowCoordinatorMixin {
  // Intentionally does NOT override initialPages, so it uses the default [].
}

class _FlowNavigatorAccessFlowCoordinator extends StatefulWidget {
  const _FlowNavigatorAccessFlowCoordinator({required this.onBuilt});

  final void Function(FlowNavigator) onBuilt;

  @override
  State<_FlowNavigatorAccessFlowCoordinator> createState() =>
      _FlowNavigatorAccessFlowCoordinatorState();
}

class _FlowNavigatorAccessFlowCoordinatorState
    extends State<_FlowNavigatorAccessFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        MaterialPage(
          child: Builder(
            builder: (context) {
              widget.onBuilt(
                FlowCoordinator.of<_FlowNavigatorAccessFlowCoordinatorState>(
                  context,
                ).flowNavigator,
              );
              return const SizedBox();
            },
          ),
        ),
      ];
}

class _RouteTrackingFlowCoordinator extends StatefulWidget {
  const _RouteTrackingFlowCoordinator({required this.onRouteReceived});

  final void Function(RouteInformation) onRouteReceived;

  @override
  State<_RouteTrackingFlowCoordinator> createState() =>
      _RouteTrackingFlowCoordinatorState();
}

class _RouteTrackingFlowCoordinatorState
    extends State<_RouteTrackingFlowCoordinator> with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(child: SizedBox()),
      ];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    widget.onRouteReceived(routeInformation);
    return SynchronousFuture(null);
  }
}

class _InitialRouteFlowCoordinator extends StatefulWidget {
  const _InitialRouteFlowCoordinator({
    required this.initialRouteInfo,
    required this.onRouteReceived,
  });

  final RouteInformation? initialRouteInfo;
  final void Function(RouteInformation) onRouteReceived;

  @override
  State<_InitialRouteFlowCoordinator> createState() =>
      _InitialRouteFlowCoordinatorState();
}

class _InitialRouteFlowCoordinatorState
    extends State<_InitialRouteFlowCoordinator> with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => [
        const MaterialPage(child: SizedBox()),
      ];

  @override
  RouteInformation? get initialRouteInformation => widget.initialRouteInfo;

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    widget.onRouteReceived(routeInformation);
    return SynchronousFuture(null);
  }
}

class _TestFlowRouteInformationProvider extends FlowRouteInformationProvider {
  final childValueNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      childValueNotifier;
}
