part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrWaterfallStream extends KiwiSdrStream {
  static void worker((int, int, String, SendPort) args) async {
    final int versionMajor = args.$1;
    final int versionMinor = args.$2;
    final Uri url = Uri.parse(args.$3);
    final SendPort sendPort = args.$4;

    await KiwiSdrWaterfallStream(
      versionMajor: versionMajor,
      versionMinor: versionMinor,
      uri: url,
      sendPort: sendPort
    ).run();
  }

  @override
  String get tag => 'W/F';

  KiwiSdrWaterfallStream({
    required super.versionMajor,
    required super.versionMinor,
    required super.uri,
    required super.sendPort,
  }) {
    setAuth('#');
    setupRxParams();
  }

  @override
  dynamic parseData(Uint8List data) {
    if (!configLoaded) return null;

    // Skip header (14 bytes)
    final waterfallData = data.sublist(14);

    return normalize(waterfallData);
  }

  Float32List normalize(Uint8List input) {
    final min = input.reduce((a, b) => a < b ? a : b);
    final max = input.reduce((a, b) => a > b ? a : b);
    final fifty = (max - min) / 3;
    final range = (max - (min + fifty)).toDouble().clamp(1.0, double.infinity); // Avoid div by 0
    final Float32List output = Float32List(input.length);

    for (int i = 0; i < input.length; i++) {
      final normalized = (input[i] - (min + fifty)) / range;
      output[i] = normalized.clamp(0.0, 1.0);
    }

    return output;
  }

  @override
  void setCompression(bool enabled) {
    sendMessage('SET wf_comp=${enabled ? 1 : 0}');
  }

  @override
  void setupRxParams() {
    setZoomCf(0, 0);
    setMaxDbMinDb(-10, -110);
    setWfSpeed(1);
    setWfInterp(13);
  }
}
