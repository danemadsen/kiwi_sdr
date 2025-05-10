part of 'package:kiwi_sdr/kiwi_sdr.dart';

class KiwiSdrException implements Exception {
  final String message;

  KiwiSdrException(this.message);

  @override
  String toString() {
    return 'KiwiSdrException: $message';
  }
}