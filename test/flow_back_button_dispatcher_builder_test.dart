import 'package:flow_coordinator/src/flow_back_button_dispatcher_builder.dart';
import 'package:flow_coordinator/src/flow_route_status_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowBackButtonDispatcherBuilder', () {
    testWidgets('provides null dispatcher when Router not found',
        (tester) async {
      ChildBackButtonDispatcher? capturedDispatcher;

      await tester.pumpWidget(
        FlowBackButtonDispatcherBuilder(
          builder: (context, dispatcher) {
            capturedDispatcher = dispatcher;
            return const SizedBox();
          },
        ),
      );

      expect(capturedDispatcher, isNull);
    });

    testWidgets('provides dispatcher when Router exists', (tester) async {
      ChildBackButtonDispatcher? capturedDispatcher;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: RouterConfig(
            routeInformationProvider: PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
            ),
            routeInformationParser: const _TestRouteInformationParser(),
            routerDelegate: _TestRouterDelegate(
              onDispatcher: (dispatcher) => capturedDispatcher = dispatcher,
            ),
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
        ),
      );

      expect(capturedDispatcher, isNotNull);
    });

    testWidgets(
        'dispatcher is null when FlowRouteStatusScope isActive is false',
        (tester) async {
      ChildBackButtonDispatcher? capturedDispatcher;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: RouterConfig(
            routeInformationProvider: PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
            ),
            routeInformationParser: const _TestRouteInformationParser(),
            routerDelegate: _TestRouterDelegate(),
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
          builder: (context, child) {
            return FlowRouteStatusScope(
              isActive: false,
              isTopRoute: true,
              child: FlowBackButtonDispatcherBuilder(
                builder: (context, dispatcher) {
                  capturedDispatcher = dispatcher;
                  return child ?? const SizedBox();
                },
              ),
            );
          },
        ),
      );

      expect(capturedDispatcher, isNull);
    });

    testWidgets(
        'dispatcher is null when FlowRouteStatusScope isTopRoute is false',
        (tester) async {
      ChildBackButtonDispatcher? capturedDispatcher;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: RouterConfig(
            routeInformationProvider: PlatformRouteInformationProvider(
              initialRouteInformation: RouteInformation(uri: Uri.parse('/')),
            ),
            routeInformationParser: const _TestRouteInformationParser(),
            routerDelegate: _TestRouterDelegate(),
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
          builder: (context, child) {
            return FlowRouteStatusScope(
              isActive: true,
              isTopRoute: false,
              child: FlowBackButtonDispatcherBuilder(
                builder: (context, dispatcher) {
                  capturedDispatcher = dispatcher;
                  return child ?? const SizedBox();
                },
              ),
            );
          },
        ),
      );

      expect(capturedDispatcher, isNull);
    });
  });
}

class _TestRouterDelegate extends RouterDelegate<RouteInformation>
    with ChangeNotifier {
  _TestRouterDelegate({this.onDispatcher});

  final ValueSetter<ChildBackButtonDispatcher?>? onDispatcher;

  @override
  Widget build(BuildContext context) {
    return FlowBackButtonDispatcherBuilder(
      builder: (context, dispatcher) {
        onDispatcher?.call(dispatcher);
        return const SizedBox();
      },
    );
  }

  @override
  Future<void> setNewRoutePath(RouteInformation configuration) async {}

  @override
  Future<bool> popRoute() async => false;
}

class _TestRouteInformationParser
    extends RouteInformationParser<RouteInformation> {
  const _TestRouteInformationParser();

  @override
  Future<RouteInformation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation;
  }
}
