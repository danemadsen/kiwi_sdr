import 'kiwi_sdr_stream.dart';

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