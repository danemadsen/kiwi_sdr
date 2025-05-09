part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrException implements Exception {
  final String message;

  KiwiSdrException(this.message);

  @override
  String toString() {
    return 'KiwiSdrException: $message';
  }
}