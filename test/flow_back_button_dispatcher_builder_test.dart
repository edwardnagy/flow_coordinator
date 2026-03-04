import 'package:flow_coordinator/src/flow_back_button_dispatcher_builder.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowBackButtonDispatcherBuilder', () {
    testWidgets(
      'builder receives a ChildBackButtonDispatcher when inside a Router',
      (tester) async {
        ChildBackButtonDispatcher? receivedDispatcher;

        await tester.pumpWidget(
          Router(
            routerDelegate: _TestRouterDelegate(
              child: FlowBackButtonDispatcherBuilder(
                builder: (context, dispatcher) {
                  receivedDispatcher = dispatcher;
                  return const SizedBox();
                },
              ),
            ),
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
        );

        expect(receivedDispatcher, isA<ChildBackButtonDispatcher>());
      },
    );

    testWidgets(
      'builder receives null when no Router ancestor exists',
      (tester) async {
        ChildBackButtonDispatcher? receivedDispatcher;

        await tester.pumpWidget(
          FlowBackButtonDispatcherBuilder(
            builder: (context, dispatcher) {
              receivedDispatcher = dispatcher;
              return const SizedBox();
            },
          ),
        );

        expect(receivedDispatcher, isNull);
      },
    );

    testWidgets(
      'builder receives null when isActive is false',
      (tester) async {
        ChildBackButtonDispatcher? receivedDispatcher;

        await tester.pumpWidget(
          Router(
            routerDelegate: _TestRouterDelegate(
              child: FlowRouteStatusScope(
                isActive: false,
                isTopRoute: true,
                child: FlowBackButtonDispatcherBuilder(
                  builder: (context, dispatcher) {
                    receivedDispatcher = dispatcher;
                    return const SizedBox();
                  },
                ),
              ),
            ),
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
        );

        expect(receivedDispatcher, isNull);
      },
    );

    testWidgets(
      'builder receives null when isTopRoute is false',
      (tester) async {
        ChildBackButtonDispatcher? receivedDispatcher;

        await tester.pumpWidget(
          Router(
            routerDelegate: _TestRouterDelegate(
              child: FlowRouteStatusScope(
                isActive: true,
                isTopRoute: false,
                child: FlowBackButtonDispatcherBuilder(
                  builder: (context, dispatcher) {
                    receivedDispatcher = dispatcher;
                    return const SizedBox();
                  },
                ),
              ),
            ),
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
        );

        expect(receivedDispatcher, isNull);
      },
    );

    testWidgets(
      'forgets old dispatcher when transitioning from enabled to disabled',
      (tester) async {
        ChildBackButtonDispatcher? initialDispatcher;
        ChildBackButtonDispatcher? latestDispatcher;
        final activeNotifier = ValueNotifier(true);
        addTearDown(activeNotifier.dispose);

        final rootDispatcher = _SpyBackButtonDispatcher();
        final delegate = _TestRouterDelegate(
          child: ValueListenableBuilder<bool>(
            valueListenable: activeNotifier,
            builder: (context, isActive, child) {
              return FlowRouteStatusScope(
                isActive: isActive,
                isTopRoute: true,
                child: child!,
              );
            },
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, dispatcher) {
                initialDispatcher ??= dispatcher;
                latestDispatcher = dispatcher;
                return const SizedBox();
              },
            ),
          ),
        );

        await tester.pumpWidget(
          Router(
            routerDelegate: delegate,
            backButtonDispatcher: rootDispatcher,
          ),
        );

        expect(initialDispatcher, isA<ChildBackButtonDispatcher>());

        activeNotifier.value = false;
        await tester.pump();

        expect(latestDispatcher, isNull);
        expect(rootDispatcher.forgottenChildren, contains(initialDispatcher));
      },
    );

    testWidgets(
      'creates dispatcher when transitioning from disabled to enabled',
      (tester) async {
        ChildBackButtonDispatcher? receivedDispatcher;
        final activeNotifier = ValueNotifier(false);
        addTearDown(activeNotifier.dispose);

        final rootDispatcher = RootBackButtonDispatcher();
        final delegate = _TestRouterDelegate(
          child: ValueListenableBuilder<bool>(
            valueListenable: activeNotifier,
            builder: (context, isActive, child) {
              return FlowRouteStatusScope(
                isActive: isActive,
                isTopRoute: true,
                child: child!,
              );
            },
            child: FlowBackButtonDispatcherBuilder(
              builder: (context, dispatcher) {
                receivedDispatcher = dispatcher;
                return const SizedBox();
              },
            ),
          ),
        );

        await tester.pumpWidget(
          Router(
            routerDelegate: delegate,
            backButtonDispatcher: rootDispatcher,
          ),
        );

        expect(receivedDispatcher, isNull);

        activeNotifier.value = true;
        await tester.pump();

        expect(receivedDispatcher, isA<ChildBackButtonDispatcher>());
      },
    );
  });
}

class _TestRouterDelegate extends RouterDelegate<void> with ChangeNotifier {
  _TestRouterDelegate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;

  @override
  Future<bool> popRoute() async => false;

  @override
  Future<void> setNewRoutePath(void configuration) async {}
}

class _SpyBackButtonDispatcher extends RootBackButtonDispatcher {
  final List<ChildBackButtonDispatcher> forgottenChildren = [];

  @override
  void forget(ChildBackButtonDispatcher child) {
    forgottenChildren.add(child);
    super.forget(child);
  }
}
