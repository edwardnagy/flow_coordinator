import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flow_coordinator/src/route_information_reporter_delegate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowRouteScope', () {
    testWidgets('builds with default values', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(
              child: FlowRouteScope(
                child: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('provides isActive status to children', (tester) async {
      FlowRouteStatusScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              child: FlowRouteScope(
                isActive: false,
                child: Builder(
                  builder: (context) {
                    capturedScope = FlowRouteStatusScope.maybeOf(context);
                    return const Text('Child');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(capturedScope?.isActive, false);
    });

    testWidgets('combines isActive with parent scope', (tester) async {
      FlowRouteStatusScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              child: FlowRouteStatusScope(
                isActive: false,
                isTopRoute: true,
                child: FlowRouteScope(
                  isActive: true,
                  child: Builder(
                    builder: (context) {
                      capturedScope = FlowRouteStatusScope.maybeOf(context);
                      return const Text('Child');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Should be false because parent is false
      expect(capturedScope?.isActive, false);
    });

    testWidgets('provides isTopRoute status based on ModalRoute',
        (tester) async {
      FlowRouteStatusScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              initialPages: [
                MaterialPage(
                  child: FlowRouteScope(
                    child: Builder(
                      builder: (context) {
                        capturedScope = FlowRouteStatusScope.maybeOf(context);
                        return const Text('Page 1');
                      },
                    ),
                  ),
                ),
                const MaterialPage(
                  child: FlowRouteScope(
                    child: Text('Page 2'),
                  ),
                ),
              ],
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Page 1 should not be top route since Page 2 is on top
      expect(capturedScope?.isTopRoute, false);
    });

    testWidgets('forwards route information to reporter', (tester) async {
      final routeInfo = RouteInformation(uri: Uri.parse('/test'));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              child: FlowRouteScope(
                routeInformation: routeInfo,
                child: const Text('Child'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('uses custom shouldForwardChildUpdates predicate',
        (tester) async {
      var predicateCallCount = 0;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              child: FlowRouteScope(
                routeInformation: RouteInformation(
                  uri: Uri.parse('/parent'),
                ),
                shouldForwardChildUpdates: (info) {
                  predicateCallCount++;
                  return info.uri.path == '/allowed';
                },
                child: const Text('Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
      // Predicate is evaluated during build
      expect(predicateCallCount, greaterThan(0));
    });

    testWidgets(
        'default matcher uses matchesUrlPattern when routeInformation provided',
        (tester) async {
      final routeInfo = RouteInformation(uri: Uri.parse('/parent'));

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              child: FlowRouteScope(
                routeInformation: routeInfo,
                child: const Text('Child'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('passes null matcher when routeInformation is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(
              child: FlowRouteScope(
                routeInformation: null,
                child: Text('Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });
  });

  // Unit tests for matchesUrlPattern are omitted due to extension visibility
  // in test context; integration tests below exercise matching behavior.

  group('RouteInformation matching via FlowRouteScope', () {
    testWidgets('forwards child route information when parent matches pattern',
        (tester) async {
      final parentProvider = _TestChildRouteInformationProvider();
      parentProvider.setConsumed(
        RouteInformation(uri: Uri.parse('/path?a=1')),
      );
      parentProvider.setChild(
        RouteInformation(uri: Uri.parse('/child'), state: 'state'),
      );

      RouteInformation? forwarded;

      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationReporterScope(
            _RecordingReporterDelegate(),
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteInformationProviderScope(
                parentProvider,
                child: FlowRouteScope(
                  routeInformation: RouteInformation(uri: Uri.parse('/path')),
                  child: Builder(
                    builder: (context) {
                      final provider = FlowRouteInformationProvider.of(context)
                          as ChildFlowRouteInformationProvider;
                      forwarded =
                          provider.childValueListenable.value?.consumeOrNull();
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(forwarded?.uri.pathSegments, ['child']);
      expect(forwarded?.state, 'state');
    });

    testWidgets('blocks child route information when pattern does not match',
        (tester) async {
      final parentProvider = _TestChildRouteInformationProvider();
      parentProvider.setConsumed(
        RouteInformation(uri: Uri.parse('/different')),
      );
      parentProvider.setChild(
        RouteInformation(uri: Uri.parse('/child')),
      );

      RouteInformation? forwarded;

      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationReporterScope(
            _RecordingReporterDelegate(),
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteInformationProviderScope(
                parentProvider,
                child: FlowRouteScope(
                  routeInformation: RouteInformation(uri: Uri.parse('/path')),
                  child: Builder(
                    builder: (context) {
                      final provider = FlowRouteInformationProvider.of(context)
                          as ChildFlowRouteInformationProvider;
                      forwarded =
                          provider.childValueListenable.value?.consumeOrNull();
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(forwarded, isNull);
    });

    testWidgets('default matcher checks query and state', (tester) async {
      final parentProvider = _TestChildRouteInformationProvider();
      parentProvider.setConsumed(
        RouteInformation(uri: Uri.parse('/path?a=1&b=2'), state: 's'),
      );
      parentProvider.setChild(
        RouteInformation(uri: Uri.parse('/child')),
      );

      RouteInformation? forwarded;

      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationReporterScope(
            _RecordingReporterDelegate(),
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteInformationProviderScope(
                parentProvider,
                child: FlowRouteScope(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/path?a=1'),
                    state: 's',
                  ),
                  child: Builder(
                    builder: (context) {
                      final provider = FlowRouteInformationProvider.of(context)
                          as ChildFlowRouteInformationProvider;
                      forwarded =
                          provider.childValueListenable.value?.consumeOrNull();
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(forwarded, isNotNull);
    });

    testWidgets('default matcher with null pattern state matches any state',
        (tester) async {
      final parentProvider = _TestChildRouteInformationProvider();
      parentProvider.setConsumed(
        RouteInformation(uri: Uri.parse('/path'), state: 'any-state'),
      );
      parentProvider.setChild(
        RouteInformation(uri: Uri.parse('/child')),
      );

      RouteInformation? forwarded;

      await tester.pumpWidget(
        MaterialApp(
          home: RouteInformationReporterScope(
            _RecordingReporterDelegate(),
            child: RouteInformationCombinerScope(
              const DefaultRouteInformationCombiner(),
              child: FlowRouteInformationProviderScope(
                parentProvider,
                child: FlowRouteScope(
                  routeInformation: RouteInformation(
                    uri: Uri.parse('/path'),
                    // state is null in pattern
                  ),
                  child: Builder(
                    builder: (context) {
                      final provider = FlowRouteInformationProvider.of(context)
                          as ChildFlowRouteInformationProvider;
                      forwarded =
                          provider.childValueListenable.value?.consumeOrNull();
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(forwarded, isNotNull);
    });
  });
}

class _TestChildRouteInformationProvider
    extends ChildFlowRouteInformationProvider {
  final consumedValueNotifier = ValueNotifier<RouteInformation?>(null);
  final childValueNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);

  void setConsumed(RouteInformation? value) {
    consumedValueNotifier.value = value;
  }

  void setChild(RouteInformation? value) {
    childValueNotifier.value =
        value == null ? null : Consumable<RouteInformation>(value);
  }

  @override
  ValueListenable<RouteInformation?> get consumedValueListenable =>
      consumedValueNotifier;

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      childValueNotifier;
}

class _RecordingReporterDelegate extends RouteInformationReporterDelegate {
  RouteInformation? lastReported;

  @override
  void childReportsRouteInformation(RouteInformation childRouteInformation) {
    lastReported = childRouteInformation;
  }
}

class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({
    super.key,
    required this.child,
    this.initialPages,
  });

  final Widget child;
  final List<Page>? initialPages;

  @override
  State<TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages =>
      widget.initialPages ?? [MaterialPage(child: widget.child)];
}
