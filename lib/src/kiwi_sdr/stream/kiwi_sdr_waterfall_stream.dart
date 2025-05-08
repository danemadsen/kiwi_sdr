part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrWaterfallStream extends KiwiSdrStream {
  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();
  final StreamController<Uint8List> _controller = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get stream => _controller.stream;

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

    // Skip header (12 bytes)
    Uint8List compressedData = data.sublist(12);
    Int16List decodedSamples = _decoder.decode(compressedData);

    // Remove decompression tail
    decodedSamples = decodedSamples.sublist(0, decodedSamples.length - 10);

    // Normalize to Uint8List
    Uint8List normalized = normalizeInt16ToUint8(decodedSamples);

    // Send normalized data instead
    _controller.sink.add(normalized);
  }

  Uint8List normalizeInt16ToUint8(Int16List input) {
    final output = Uint8List(input.length);
    for (int i = 0; i < input.length; i++) {
      // Clamp to prevent overflow if data has -32768
      int clamped = input[i].clamp(-32767, 32767);
      // Normalize to 0..1, then scale to 0..255
      double normalized = (clamped + 32767) / 65534.0;
      output[i] = (normalized * 255).round().clamp(0, 255);
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
