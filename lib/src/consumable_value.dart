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
