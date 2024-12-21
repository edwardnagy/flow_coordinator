import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/subjects.dart';

abstract interface class RouteInformationProcessor {
  /// Creates a new [RouteInformation] by combining the current state of the flow
  /// with the provided [childRouteInformation].
  RouteInformation? createRouteInformation({
    required RouteInformation childRouteInformation,
  });
}

abstract class FlowRouteInformationProvider extends RouteInformationProvider {
  /// The value that child (nested) flow coordinators can consume.
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream;

  ConsumableValue<RouteInformation>? get childConsumableValue;

  void childReportsNewRouteInformation(
    RouteInformation childRouteInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  });
}

/// A wrapper for values that ensures single-use consumption.
///
/// Used to encapsulate values, such as route information, that should
/// only be processed once. After being consumed, the value is marked
/// as consumed and ignored by other listeners.
///
/// Example:
/// ```dart
/// final value = ConsumableValue('Navigate to home');
/// if (!value.isConsumed) {
///   print(value.value); // Use the value.
///   value.isConsumed = true; // Mark as consumed.
/// }
/// ```
class ConsumableValue<T> {
  /// Creates a consumable value.
  ConsumableValue(this.value, {this.isConsumed = false});

  /// The wrapped value.
  final T value;

  /// Whether this value has been consumed.
  ///
  /// Once consumed, it should not be used again.
  bool isConsumed;

  T? getAndConsumeOrNull() {
    if (isConsumed) return null;
    isConsumed = true;
    return value;
  }
}

class RootFlowRouteInformationProvider extends PlatformRouteInformationProvider
    implements FlowRouteInformationProvider {
  RootFlowRouteInformationProvider({required super.initialRouteInformation}) {
    addListener(_onValueUpdated);
  }

  late final _childConsumableValueController =
      BehaviorSubject<ConsumableValue<RouteInformation>>.seeded(
    ConsumableValue(value),
  );

  RouteInformation? _pendingReportedRouteInformation;

  @override
  ConsumableValue<RouteInformation>? get childConsumableValue =>
      _childConsumableValueController.value;

  @override
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream =>
      _childConsumableValueController.stream;

  @override
  void dispose() {
    removeListener(_onValueUpdated);
    _childConsumableValueController.close();
    super.dispose();
  }

  void _onValueUpdated() {
    _childConsumableValueController.add(ConsumableValue(value));
  }

  @override
  void childReportsNewRouteInformation(
    RouteInformation childRouteInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    // Reports only the last update in case of multiple synchronous updates.
    // This avoids interfering with browser history, which can break the
    // back and forward navigation buttons.
    _pendingReportedRouteInformation = childRouteInformation;
    Future.microtask(() {
      // Ignore this update if the route information has changed since this
      // call.
      if (_pendingReportedRouteInformation != childRouteInformation) {
        return;
      }
      routerReportsNewRouteInformation(childRouteInformation, type: type);
    });
  }
}

class ChildFlowRouteInformationProvider extends FlowRouteInformationProvider
    with ChangeNotifier {
  ChildFlowRouteInformationProvider({
    required this.parent,
    required this.routeInformationProcessor,
    required RouteInformation initialValue,
  }) : _value =
            parent.childConsumableValue?.getAndConsumeOrNull() ?? initialValue {
    _consumableValueSubscription =
        parent.childConsumableValueStream.listen(_onValueReceivedFromParent);
  }

  final FlowRouteInformationProvider parent;
  final RouteInformationProcessor routeInformationProcessor;

  StreamSubscription? _consumableValueSubscription;

  final _childConsumableValueController =
      BehaviorSubject<ConsumableValue<RouteInformation>>();

  @override
  RouteInformation get value => _value;
  RouteInformation _value;

  @override
  ConsumableValue<RouteInformation>? get childConsumableValue =>
      _childConsumableValueController.valueOrNull;

  @override
  Stream<ConsumableValue<RouteInformation>> get childConsumableValueStream =>
      _childConsumableValueController.stream;

  void _onValueReceivedFromParent(
    ConsumableValue<RouteInformation> consumableValue,
  ) {
    final value = consumableValue.getAndConsumeOrNull();
    if (value == null || value == _value) return;

    _value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _consumableValueSubscription?.cancel();
    _childConsumableValueController.close();
    super.dispose();
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _value = routeInformation;
    parent.childReportsNewRouteInformation(
      routeInformation,
      type: type,
    );
  }

  @override
  void childReportsNewRouteInformation(
    RouteInformation childRouteInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    // Update the child route information.
    _childConsumableValueController.add(
      ConsumableValue(childRouteInformation, isConsumed: true),
    );
    final routeInformation = routeInformationProcessor.createRouteInformation(
      childRouteInformation: childRouteInformation,
    );
    if (routeInformation == null) {
      // TODO: Log the error.
      return;
    }
    parent.childReportsNewRouteInformation(routeInformation, type: type);
  }

  void setChildValue(RouteInformation childValue) {
    if (childValue == _childConsumableValueController.valueOrNull?.value) {
      return;
    }
    _childConsumableValueController.add(ConsumableValue(childValue));
  }
}
