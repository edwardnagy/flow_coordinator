import 'package:flow_coordinator/src/consumable.dart';
import 'package:flow_coordinator/src/flow_coordinator_mixin.dart';
import 'package:flow_coordinator/src/flow_coordinator_router.dart';
import 'package:flow_coordinator/src/flow_route_information_provider.dart';
import 'package:flow_coordinator/src/flow_route_scope.dart';
import 'package:flow_coordinator/src/route_information_combiner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A flow coordinator that uses the default (empty) initialPages.
class _DefaultPagesFlowCoordinator extends StatefulWidget {
  const _DefaultPagesFlowCoordinator();

  @override
  State<_DefaultPagesFlowCoordinator> createState() =>
      _DefaultPagesFlowCoordinatorState();
}

class _DefaultPagesFlowCoordinatorState
    extends State<_DefaultPagesFlowCoordinator> with FlowCoordinatorMixin {
  @override
  Widget build(BuildContext context) => flowRouter(context);
}

/// A test FlowRouteInformationProvider for swapping in the widget tree.
class _TestFlowRouteInfoProvider implements FlowRouteInformationProvider {
  final childNotifier = ValueNotifier<Consumable<RouteInformation>?>(null);

  @override
  ValueListenable<Consumable<RouteInformation>?> get childValueListenable =>
      childNotifier;

  void dispose() => childNotifier.dispose();
}

// Minimal flow coordinator for testing
class _TestFlowCoordinator extends StatefulWidget {
  const _TestFlowCoordinator({
    this.initialPages,
    this.initialRouteInformation,
    this.onNewRouteInformationCallback,
    this.onBuild,
  });

  final List<Page>? initialPages;
  final RouteInformation? initialRouteInformation;
  final Future<RouteInformation?> Function(RouteInformation)?
      onNewRouteInformationCallback;
  final void Function(_TestFlowCoordinatorState)? onBuild;

  @override
  State<_TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<_TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages =>
      widget.initialPages ??
      [
        const MaterialPage(
          key: ValueKey('initial'),
          child: SizedBox(),
        ),
      ];

  @override
  RouteInformation? get initialRouteInformation =>
      widget.initialRouteInformation;

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) {
    if (widget.onNewRouteInformationCallback != null) {
      return widget.onNewRouteInformationCallback!(
        routeInformation,
      );
    }
    return super.onNewRouteInformation(routeInformation);
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call(this);
    return flowRouter(context);
  }
}

Widget _buildTestApp({
  required WidgetBuilder homeBuilder,
  Uri? initialUri,
}) {
  return WidgetsApp.router(
    routerConfig: FlowCoordinatorRouter(
      homeBuilder: homeBuilder,
      initialUri: initialUri,
    ),
    color: const Color(0xFF000000),
  );
}

void main() {
  group('FlowCoordinatorMixin', () {
    testWidgets(
      'builds successfully with default initialPages',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => const _TestFlowCoordinator(
              initialPages: [
                MaterialPage(
                  child: Text('Page 1'),
                ),
              ],
            ),
          ),
        );

        expect(find.text('Page 1'), findsOneWidget);
      },
    );

    testWidgets(
      'flowNavigator is accessible from descendants',
      (tester) async {
        late FlowNavigator navigator;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: [
                MaterialPage(
                  child: Builder(
                    builder: (context) {
                      navigator = FlowNavigator.of(context);
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        expect(navigator.canPopInternally(), isFalse);
      },
    );

    testWidgets(
      'flowNavigator can push pages',
      (tester) async {
        _TestFlowCoordinatorState? state;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: const [
                MaterialPage(
                  child: Text('Page 1'),
                ),
              ],
              onBuild: (s) => state = s,
            ),
          ),
        );

        state!.flowNavigator.push(
          const MaterialPage(child: Text('Page 2')),
        );
        await tester.pump();

        expect(find.text('Page 2'), findsOneWidget);
      },
    );

    testWidgets(
      'onNewRouteInformation is called with default return',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: const [
                MaterialPage(child: SizedBox()),
              ],
              onNewRouteInformationCallback: (info) {
                called = true;
                return SynchronousFuture(null);
              },
            ),
            initialUri: Uri.parse('/test'),
          ),
        );

        expect(called, isTrue);
      },
    );

    testWidgets(
      'onNewRouteInformation forwards child route info',
      (tester) async {
        Consumable<RouteInformation>? childValue;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: [
                MaterialPage(
                  child: Builder(
                    builder: (context) {
                      final provider = FlowRouteInformationProvider.of(context);
                      childValue = provider.childValueListenable.value;
                      return const SizedBox();
                    },
                  ),
                ),
              ],
              onNewRouteInformationCallback: (info) {
                return SynchronousFuture(
                  RouteInformation(
                    uri: Uri.parse('/child-route'),
                  ),
                );
              },
            ),
            initialUri: Uri.parse('/test'),
          ),
        );

        expect(
          childValue?.consumeOrNull()?.uri,
          Uri.parse('/child-route'),
        );
      },
    );

    testWidgets(
      'setNewRouteInformation triggers onNewRouteInformation',
      (tester) async {
        _TestFlowCoordinatorState? state;
        RouteInformation? receivedInfo;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: const [
                MaterialPage(child: SizedBox()),
              ],
              onNewRouteInformationCallback: (info) {
                receivedInfo = info;
                return SynchronousFuture(null);
              },
              onBuild: (s) => state = s,
            ),
          ),
        );

        state!.setNewRouteInformation(
          RouteInformation(uri: Uri.parse('/custom')),
        );

        expect(receivedInfo?.uri, Uri.parse('/custom'));
      },
    );

    testWidgets(
      'initialRouteInformation is applied on first build',
      (tester) async {
        RouteInformation? receivedInfo;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: const [
                MaterialPage(child: SizedBox()),
              ],
              initialRouteInformation: RouteInformation(
                uri: Uri.parse('/initial-route'),
              ),
              onNewRouteInformationCallback: (info) {
                receivedInfo = info;
                return SynchronousFuture(null);
              },
            ),
          ),
        );

        expect(
          receivedInfo?.uri,
          Uri.parse('/initial-route'),
        );
      },
    );

    testWidgets(
      'initialRouteInformation is not applied after custom '
      'route information',
      (tester) async {
        final receivedUris = <Uri>[];
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: const [
                MaterialPage(child: SizedBox()),
              ],
              initialRouteInformation: RouteInformation(
                uri: Uri.parse('/initial'),
              ),
              onNewRouteInformationCallback: (info) {
                receivedUris.add(info.uri);
                return SynchronousFuture(null);
              },
            ),
            initialUri: Uri.parse('/custom'),
          ),
        );

        // Should have been called with /custom but not with /initial
        // because custom route info takes precedence
        expect(receivedUris, contains(Uri.parse('/custom')));
        expect(receivedUris, isNot(contains(Uri.parse('/initial'))));
      },
    );

    testWidgets(
      'routeInformationCombiner defaults to '
      'DefaultRouteInformationCombiner',
      (tester) async {
        _TestFlowCoordinatorState? state;
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: const [
                MaterialPage(child: SizedBox()),
              ],
              onBuild: (s) => state = s,
            ),
          ),
        );

        expect(
          state!.routeInformationCombiner,
          isA<DefaultRouteInformationCombiner>(),
        );
      },
    );

    testWidgets(
      'asserts when initialPages is empty',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => const _DefaultPagesFlowCoordinator(),
          ),
        );

        final error = tester.takeException();
        expect(error, isA<AssertionError>());
        expect(
          error.toString(),
          contains('The pages list must not be empty'),
        );
      },
    );

    testWidgets(
      'removes listener from old parent provider when provider changes',
      (tester) async {
        final providerA = _TestFlowRouteInfoProvider();
        final providerB = _TestFlowRouteInfoProvider();
        final currentProvider =
            ValueNotifier<FlowRouteInformationProvider>(providerA);
        RouteInformation? receivedAfterSwap;
        addTearDown(() {
          currentProvider.dispose();
          providerA.dispose();
          providerB.dispose();
        });

        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) =>
                ValueListenableBuilder<FlowRouteInformationProvider>(
              valueListenable: currentProvider,
              builder: (_, provider, __) => FlowRouteInformationProviderScope(
                provider,
                child: _TestFlowCoordinator(
                  initialPages: const [
                    MaterialPage(child: SizedBox()),
                  ],
                  onNewRouteInformationCallback: (info) {
                    receivedAfterSwap = info;
                    return SynchronousFuture(null);
                  },
                ),
              ),
            ),
          ),
        );

        // Swap the provider to trigger didChangeDependencies with a
        // non-null _parentRouteInformationProvider, exercising the
        // removeListener call.
        currentProvider.value = providerB;
        await tester.pump();

        // Clear any route info received during the swap itself.
        receivedAfterSwap = null;

        // Fire a change on the OLD provider — listener should have
        // been removed, so the flow coordinator must NOT receive it.
        providerA.childNotifier.value = Consumable(
          RouteInformation(uri: Uri.parse('/from-old-provider')),
        );
        await tester.pump();

        expect(receivedAfterSwap, isNull);
      },
    );

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          homeBuilder: (_) => const _TestFlowCoordinator(
            initialPages: [
              MaterialPage(child: SizedBox()),
            ],
          ),
        ),
      );

      // Replace with different widget to trigger dispose
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'FlowRouteScope integration - reports route info',
      (tester) async {
        final router = FlowCoordinatorRouter(
          homeBuilder: (_) => _TestFlowCoordinator(
            initialPages: [
              MaterialPage(
                child: Builder(
                  builder: (context) => FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/books'),
                    ),
                    child: const Text('Books'),
                  ),
                ),
              ),
            ],
          ),
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          WidgetsApp.router(
            routerConfig: router,
            color: const Color(0xFF000000),
          ),
        );
        // Pump extra frames for post-frame reporting callbacks.
        for (var i = 0; i < 3; i++) {
          tester.binding.scheduleFrame();
          await tester.pump();
        }

        expect(find.text('Books'), findsOneWidget);
        expect(
          router.routerDelegate.currentConfiguration?.uri,
          Uri.parse('/books'),
        );
      },
    );

    testWidgets(
      'child flow coordinator receives route info from parent',
      (tester) async {
        _TestFlowCoordinatorState? parentState;
        RouteInformation? childReceivedInfo;

        await tester.pumpWidget(
          _buildTestApp(
            homeBuilder: (_) => _TestFlowCoordinator(
              initialPages: [
                MaterialPage(
                  child: FlowRouteScope(
                    routeInformation: RouteInformation(
                      uri: Uri.parse('/parent'),
                    ),
                    shouldForwardChildUpdates: (_) => true,
                    child: _TestFlowCoordinator(
                      initialPages: const [
                        MaterialPage(
                          child: SizedBox(),
                        ),
                      ],
                      onNewRouteInformationCallback: (info) {
                        childReceivedInfo = info;
                        return SynchronousFuture(null);
                      },
                    ),
                  ),
                ),
              ],
              onBuild: (s) => parentState = s,
              onNewRouteInformationCallback: (info) {
                return SynchronousFuture(
                  RouteInformation(
                    uri: Uri.parse('/forwarded'),
                  ),
                );
              },
            ),
          ),
        );

        parentState!.setNewRouteInformation(
          RouteInformation(uri: Uri.parse('/new-route')),
        );

        expect(childReceivedInfo, isNotNull);
        expect(childReceivedInfo!.uri, Uri.parse('/forwarded'));
      },
    );
  });
}
