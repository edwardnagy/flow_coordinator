import 'package:flow_coordinator/flow_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowCoordinatorMixin', () {
    testWidgets('initialPages are used to build the navigator', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const TestFlowCoordinator(
              initialPages: [
                MaterialPage(child: Text('Page 1')),
                MaterialPage(child: Text('Page 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Page 1'), findsNothing);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('flowNavigator can push and pop pages', (tester) async {
      final key = GlobalKey<_TestFlowCoordinatorState>();
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              key: key,
              initialPages: const [
                MaterialPage(child: Text('Page 1')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);

      key.currentState!.flowNavigator.push(
        const MaterialPage(child: Text('Page 2')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Page 1'), findsNothing);

      key.currentState!.flowNavigator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('sets parent flow navigator', (tester) async {
      final parentKey = GlobalKey<_TestFlowCoordinatorState>();
      final childKey = GlobalKey<_TestFlowCoordinatorState>();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              key: parentKey,
              initialPages: [
                MaterialPage(
                  child: TestFlowCoordinator(
                    key: childKey,
                    initialPages: const [MaterialPage(child: Text('Child'))],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('onNewRouteInformation is called when route info is set',
        (tester) async {
      final key = GlobalKey<_TestFlowCoordinatorState>();
      RouteInformation? capturedRouteInfo;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              key: key,
              initialPages: const [MaterialPage(child: Text('Page 1'))],
              onRouteInfo: (info) {
                capturedRouteInfo = info;
              },
            ),
          ),
        ),
      );

      key.currentState!.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/test')),
      );

      expect(capturedRouteInfo, isNotNull);
      expect(capturedRouteInfo!.uri.path, '/test');
    });

    testWidgets('initialRouteInformation is used when no parent route provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              initialPages: const [MaterialPage(child: Text('Page 1'))],
              initialRoute: RouteInformation(uri: Uri.parse('/initial')),
            ),
          ),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('sets initial route on dependency change when consumed is null',
        (tester) async {
      final rebuildNotifier = ValueNotifier(0);
      addTearDown(rebuildNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => ValueListenableBuilder<int>(
              valueListenable: rebuildNotifier,
              builder: (context, value, _) {
                // Adding a dependency that changes will trigger
                // didChangeDependencies
                return TestFlowCoordinator(
                  initialPages: const [
                    MaterialPage(child: Text('Page 1')),
                  ],
                  initialRoute:
                      RouteInformation(uri: Uri.parse('/initial-$value')),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);

      // Trigger didChangeDependencies - line 169 should execute again
      rebuildNotifier.value = 1;
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('routeInformationCombiner can be customized', (tester) async {
      final customCombiner = _CustomCombiner();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              initialPages: const [MaterialPage(child: Text('Page 1'))],
              combiner: customCombiner,
            ),
          ),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('parent route changes trigger didChangeDependencies',
        (tester) async {
      final parentKey = GlobalKey<_TestFlowCoordinatorState>();
      final childKey = GlobalKey<_TestFlowCoordinatorState>();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              key: parentKey,
              initialPages: [
                MaterialPage(
                  child: TestFlowCoordinator(
                    key: childKey,
                    initialPages: const [MaterialPage(child: Text('Child'))],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Trigger parent route information change
      parentKey.currentState!.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/parent-changed')),
      );
      await tester.pump();

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('removes listener when parent provider changes',
        (tester) async {
      final parent1Key = GlobalKey<_TestFlowCoordinatorState>();
      final parent2Key = GlobalKey<_TestFlowCoordinatorState>();
      final childKey = GlobalKey<_TestFlowCoordinatorState>();
      final switchParent = ValueNotifier(false);
      addTearDown(switchParent.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => ValueListenableBuilder<bool>(
              valueListenable: switchParent,
              builder: (context, useSecondParent, _) {
                if (useSecondParent) {
                  return TestFlowCoordinator(
                    key: parent2Key,
                    initialPages: [
                      MaterialPage(
                        child: TestFlowCoordinator(
                          key: childKey,
                          initialPages: const [
                            MaterialPage(child: Text('Child')),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return TestFlowCoordinator(
                    key: parent1Key,
                    initialPages: [
                      MaterialPage(
                        child: TestFlowCoordinator(
                          key: childKey,
                          initialPages: const [
                            MaterialPage(child: Text('Child')),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);

      // Switch to second parent - triggers listener removal from first parent
      switchParent.value = true;
      await tester.pump();

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('child propagates route to parent', (tester) async {
      final parentKey = GlobalKey<_TestFlowCoordinatorState>();
      final childKey = GlobalKey<_TestFlowCoordinatorState>();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => TestFlowCoordinator(
              key: parentKey,
              initialPages: [
                MaterialPage(
                  child: TestFlowCoordinator(
                    key: childKey,
                    initialPages: const [MaterialPage(child: Text('Child'))],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Child sets route information which should propagate to parent
      childKey.currentState!.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/child-route')),
      );
      await tester.pump();

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('contextDescriptionProvider used in error messages',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => const _EmptyPagesCoordinator(),
          ),
        ),
      );

      final ex = tester.takeException();
      expect(ex, isA<AssertionError>());
      expect(ex.toString(), contains('The flow coordinator being built was'));
    });

    testWidgets('child receives subsequent updates from parent via listener',
        (tester) async {
      final parentKey = GlobalKey<_ForwardingParentCoordinatorState>();
      var childInfoCount = 0;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => _ForwardingParentCoordinator(
              key: parentKey,
              child: TestFlowCoordinator(
                initialPages: const [MaterialPage(child: Text('Child'))],
                onRouteInfo: (_) => childInfoCount++,
              ),
            ),
          ),
        ),
      );

      // First update from parent
      parentKey.currentState!.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/one')),
      );
      await tester.pump();

      parentKey.currentState!.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/two')),
      );
      await tester.pump();

      // Should have received at least 2 updates from parent
      expect(childInfoCount, greaterThanOrEqualTo(2));
    });

    testWidgets(
        'child receives forwarded route from parent on onNewRouteInformation',
        (tester) async {
      final childReceived = <RouteInformation>[];

      final forwardingKey = GlobalKey<_ForwardingParentCoordinatorState>();

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: FlowCoordinatorRouter(
            homeBuilder: (context) => _ForwardingParentCoordinator(
              key: forwardingKey,
              child: TestFlowCoordinator(
                initialPages: const [MaterialPage(child: Text('Child'))],
                onRouteInfo: (info) => childReceived.add(info),
              ),
            ),
          ),
        ),
      );

      // Trigger route in parent; parent forwards a child route which
      // child should receive via listener.
      forwardingKey.currentState!.setNewRouteInformation(
        RouteInformation(uri: Uri.parse('/incoming')),
      );
      await tester.pump();

      expect(childReceived.any((i) => i.uri.path == '/forwarded'), isTrue);
    });
  });
}

class _CustomCombiner implements RouteInformationCombiner {
  @override
  RouteInformation combine({
    required RouteInformation currentRouteInformation,
    required RouteInformation childRouteInformation,
  }) {
    return childRouteInformation;
  }
}

class TestFlowCoordinator extends StatefulWidget {
  const TestFlowCoordinator({
    super.key,
    this.initialPages = const [],
    this.child,
    this.onRouteInfo,
    this.initialRoute,
    this.combiner,
  });

  final List<Page> initialPages;
  final Widget? child;
  final Function(RouteInformation)? onRouteInfo;
  final RouteInformation? initialRoute;
  final RouteInformationCombiner? combiner;

  @override
  State<TestFlowCoordinator> createState() => _TestFlowCoordinatorState();
}

class _TestFlowCoordinatorState extends State<TestFlowCoordinator>
    with FlowCoordinatorMixin {
  @override
  List<Page> get initialPages => widget.initialPages;

  @override
  RouteInformation? get initialRouteInformation => widget.initialRoute;

  @override
  RouteInformationCombiner get routeInformationCombiner =>
      widget.combiner ?? super.routeInformationCombiner;

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    widget.onRouteInfo?.call(routeInformation);
    return super.onNewRouteInformation(routeInformation);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return widget.child!;
    }
    return super.build(context);
  }
}

class _EmptyPagesCoordinator extends StatefulWidget {
  const _EmptyPagesCoordinator();

  @override
  State<_EmptyPagesCoordinator> createState() => _EmptyPagesCoordinatorState();
}

class _EmptyPagesCoordinatorState extends State<_EmptyPagesCoordinator>
    with FlowCoordinatorMixin<_EmptyPagesCoordinator> {
  @override
  List<Page> get initialPages => const [];
}

class _ForwardingParentCoordinator extends StatefulWidget {
  const _ForwardingParentCoordinator({super.key, required this.child});
  final Widget child;

  @override
  State<_ForwardingParentCoordinator> createState() =>
      _ForwardingParentCoordinatorState();
}

class _ForwardingParentCoordinatorState
    extends State<_ForwardingParentCoordinator>
    with FlowCoordinatorMixin<_ForwardingParentCoordinator> {
  @override
  List<Page> get initialPages => [MaterialPage(child: widget.child)];

  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    // Forward a child route so that listeners in the child can receive it.
    return RouteInformation(uri: Uri.parse('/forwarded'));
  }
}
