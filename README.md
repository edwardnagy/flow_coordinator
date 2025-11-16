A navigation and routing API that organizes screens into *user flows*, using the
Flow Controller (Coordinator) pattern.

![Flow Coordinator Illustration](https://raw.githubusercontent.com/edwardnagy/flow_coordinator/refs/heads/main/doc/flow-coordinator-illustration.svg?token=GHSAT0AAAAAADOMVI5ZAO55SHQVNT6QOJI62IZWQEQ)

## Features

Use Flow Coordinators in order to:

- Reuse screens and flows across different parts of your app.
- Separate complex navigation logic from UI code.
- Handle deep linking and complex routing scenarios modularly.
- Guard screens from unauthorized access — for example, redirect to login if the
user is not authenticated.
- Support nested navigators and flows.
- Support state restoration.
- Preserve compatibility with the Navigator API.

## Getting started

To configure your app, set the `routerConfig` parameter of `MaterialApp.router`
or `CupertinoApp.router` to use `FlowCoordinatorRouter` as the root router:

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

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
