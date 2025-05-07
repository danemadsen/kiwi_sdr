part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrExtensionStream extends KiwiSdrStream {
  KiwiSdrExtensionStream({
    required super.versionMajor, 
    required super.versionMinor, 
    required super.uri
  });

  @override
  void setCompression(bool enabled) {
    throw UnimplementedError();
  }

  @override
  void setupRxParams() {
    throw UnimplementedError();
  }
}