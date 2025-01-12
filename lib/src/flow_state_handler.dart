// TODO: Add documentation
import 'package:flutter/foundation.dart';

abstract interface class FlowStateHandler<T> {
  /// Called when a new route has been pushed to the application by the
  /// operating system.
  ///
  /// Consider using a [SynchronousFuture] if the result can be computed
  /// synchronously to avoid waiting for the next microtask to schedule a build.
  Future<void> setNewFlowState(T flowState);

  // TODO: Add documentation
  Future<void> setInitialFlowState(T flowState);

  // TODO: Add documentation
  Future<void> setRestoredFlowState(T flowState);
}
