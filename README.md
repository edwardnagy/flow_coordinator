A navigation and routing API that organizes screens into *user flows*, using the
Flow Controller (Coordinator) pattern.

![Flow Coordinator Illustration](https://github.com/user-attachments/assets/b356c195-48a8-4f36-9415-8d9344f5324d)

## Features

Use Flow Coordinators to:

- Reuse screens and flows across different parts of your app.
- Separate complex navigation logic from UI code.
- Handle deep linking and complex routing scenarios modularly.
- Update the browser URL to reflect the current route.
- Restore the app state after termination.
- Guard screens from unauthorized access — for example, redirect to login if the
user is not authenticated.
- Support nested routing with tabs.
- Preserve compatibility with the Navigator API.

## Getting Started

To configure your app, set the `routerConfig` parameter of `MaterialApp.router`
or `CupertinoApp.router` to a `FlowCoordinatorRouter`, and provide a builder for
the root Flow Coordinator of your app:

```dart
import 'package:flow_coordinator/flow_coordinator.dart';

final _router = FlowCoordinatorRouter(
    homeBuilder: (context) => const MyFlowCoordinator(),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}
```

## Usage

This section has code examples for the following tasks:

- [Navigating Between Screens](#navigating-between-screens)
- [Deep Link Handling](#deep-link-handling)
- [Updating the Browser URL](#updating-the-browser-url)
- [Tabbed Navigation with Nested Routing](#tabbed-navigation-with-nested-routing)

A complete example app that meets all navigation requirements identified by the
Flutter team in their [Routing API Usability Research](https://github.com/flutter/uxr/blob/master/docs/Flutter-Routing-API-Usability-Research.md)
as “important yet difficult to implement” is available in the [example](example/)
directory.

### Navigating Between Screens

Create an interface for your screen's navigation events. The interface should implement
`FlowCoordinatorMixin`:

```dart
abstract interface class MyScreenListener<T extends StatefulWidget>
    implements FlowCoordinatorMixin<T> {
  void onButtonPressed();
}
```

In your screen widget, use `FlowCoordinatorMixin.of<MyScreenListener>(context)`
to retrieve the nearest Flow Coordinator that implements the listener interface.
Call the appropriate method when a navigation event occurs:

```dart
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final listener = FlowCoordinatorMixin.of<MyScreenListener>(context);
            listener.onButtonPressed();
          },
          child: const Text('Go to Next Screen'),
        ),
      ),
    );
  }
}
```

Define the Flow Coordinator that manages the screen. This needs
to be a StatefulWidget that mixes in `FlowCoordinatorMixin` and implements the
listener interface created earlier. Set your screen as `initialPages` of the flow.
Then, implement the navigation logic of the listener methods using the
`flowNavigator` to push, pop, or replace pages:

```dart
class MyFlowCoordinator extends StatefulWidget {
  const MyFlowCoordinator({super.key});

  @override
  State<MyFlowCoordinator> createState() => _MyFlowCoordinatorState();
}

class _MyFlowCoordinatorState
    with FlowCoordinatorMixin<MyFlowCoordinator>
    implements MyScreenListener<MyFlowCoordinator> {
  @override
  List<Page> get initialPages => [const MaterialPage(child: MyScreen())];

  @override
  void onButtonPressed() {
    flowNavigator.push(MaterialPage(child: MyNextScreen()));
  }
}
```

You can set this Flow Coordinator as the root of your app, or push it from another
Flow Coordinator just like a regular screen.

#### Navigating Back

Use `flowNavigator.pop()` from inside a Flow Coordinator,
or `FlowNavigator.of(context).pop()` from inside a screen,
to navigate back to the previous screen in the navigation stack. This ensures that
the correct screen/flow is popped even in case the previous screen is managed by
a different Flow Coordinator.

```dart
class MyNextScreen extends StatelessWidget {
  const MyNextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Next Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            FlowNavigator.of(context).pop();
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
```

Android back button handling is automatically delegated to the topmost navigator
— no additional configuration is needed.

### Deep Link Handling

Override the `onNewRouteInformation` method of your Flow
Coordinator's FlowCoordinatorMixin to handle incoming deep links:

```dart
class _MyFlowCoordinatorState with FlowCoordinatorMixin<MyFlowCoordinator> {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (routeInformation.uri.pathSegments.firstOrNull == 'next') {
      flowNavigator.push(MaterialPage(child: MyNextScreen()));
    }
    return SynchronousFuture(null);
  }
}
```

Note, return a `SynchronousFuture` if the deep link can be handled synchronously
to avoid waiting for the next microtask to schedule the build.

#### Nested Routing

If part of the deep link should be handled by a child Flow Coordinator,
build and return a `RouteInformation` object from the `onNewRouteInformation`
that contains the remaining part of the deep link.
The child Flow Coordinator will receive it in its own `onNewRouteInformation` method.

```dart
class _HomeFlowCoordinatorState with FlowCoordinatorMixin<HomeFlowCoordinator> {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    RouteInformation? childRouteInformation;
    switch (routeInformation.uri.pathSegments.firstOrNull) {
      case 'profile':
        flowNavigator.setPages([
          MaterialPage(key: Key('profile'), child: ProfileFlowCoordinator()),
        ]);
        childRouteInformation = RouteInformation(
          uri: Uri(pathSegments: routeInformation.uri.pathSegments.sublist(1)),
        );
      case 'settings':
        flowNavigator.setPages([
          MaterialPage(key: Key('settings'), child: SettingsScreen()),
        ]);
    }
    return SynchronousFuture(childRouteInformation);
  }
}
```

### Updating the Browser URL

Wrap your screen widgets with `FlowRouteScope` to update the browser URL when navigating
between screens. Set `routeInformation` to the desired URL for each screen. The browser
address bar will reflect the URL of the topmost `FlowRouteScope` in
the navigation stack, even when navigating back using in-app or Android back buttons.

```dart
class _MyFlowCoordinatorState with FlowCoordinatorMixin<MyFlowCoordinator> {
  @override
  Future<RouteInformation?> onNewRouteInformation(
    RouteInformation routeInformation,
  ) async {
    flowNavigator.setPages([
      FlowRouteScope(
        // Update URL to '/' when MyScreen is active.
        routeInformation: RouteInformation(uri: Uri()),
        child: MyScreen(),
      ),
      if (routeInformation.uri.pathSegments.firstOrNull == 'next')
        // Update URL to '/next' when MyNextScreen is active.
        FlowRouteScope(
          routeInformation: RouteInformation(uri: Uri(pathSegments: ['next'])),
          child: MyNextScreen(),
        ),
    ]);
    return SynchronousFuture(null);
  }
}
```

### Tabbed Navigation with Nested Routing

## Additional Information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
