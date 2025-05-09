part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrWaterfallStream extends KiwiSdrStream {
  final StreamController<Float32List> _controller = StreamController<Float32List>.broadcast();

  Stream<Float32List> get stream => _controller.stream;

  KiwiSdrWaterfallStream({
    required super.versionMajor,
    required super.versionMinor,
    required super.uri,
  }) {
    setAuth('#');
    setupRxParams();
  }

  @override
  void onData(String tag, Uint8List data) {
    if (tag != 'W/F') developer.log('KiwiSdrWaterfallStream: $tag');
    if (!configLoaded) return;

    // Skip header (14 bytes)
    final waterfallData = data.sublist(14);

    final normalized = normalize(waterfallData);

    // Send normalized data instead
    _controller.sink.add(normalized);
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

  @override
  void close() {
    super.close();
    _controller.close();
  }
}
