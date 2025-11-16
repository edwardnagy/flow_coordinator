A navigation and routing API that organizes screens into *user flows*, using the
Flow Controller (Coordinator) pattern.

![Flow Coordinator Illustration](https://github.com/user-attachments/assets/b356c195-48a8-4f36-9415-8d9344f5324d)

## Features

Use Flow Coordinators to:

- Reuse screens and flows across different parts of your app.
- Separate complex navigation logic from UI code.
- Handle deep linking and complex routing scenarios modularly.
- Synchronize the browser URL with the active route.
- Restore the app state after termination.
- Guard screens from unauthorized access — for example, redirect to login if the
user is not authenticated.
- Support nested routing with tabs.
- Preserve compatibility with the Navigator API.

## Getting started

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

- [Navigating between screens](#navigating-between-screens)
- [Handling deep links](#handling-deep-links)
- [Synchronizing the browser URL](#synchronizing-the-browser-url)
- [Nested routing with tabs](#nested-routing-with-tabs)

A complete example app that meets all navigation requirements identified by the
Flutter team in their [Routing API Usability Research](https://github.com/flutter/uxr/blob/master/docs/Flutter-Routing-API-Usability-Research.md)
as “important yet difficult to implement” is available in the [example](example/)
directory.

### Navigating between screens

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

#### Navigating back

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

### Handling deep links

### Synchronizing the browser URL

### Nested routing with tabs

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
