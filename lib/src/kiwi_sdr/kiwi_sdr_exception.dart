part of 'package:kiwi_sdr/kiwi_sdr.dart';

/// An exception class for handling errors related to KiwiSDR operations.
class KiwiSdrException implements Exception {
  /// The error message associated with the exception.
  final String message;

  /// Creates a new instance of [KiwiSdrException] with the provided [message].
  KiwiSdrException(this.message);

  @override
  String toString() {
    return 'KiwiSdrException: $message';
  }
}
