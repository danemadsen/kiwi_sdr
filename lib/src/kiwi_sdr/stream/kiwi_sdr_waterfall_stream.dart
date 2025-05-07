part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrWaterfallStream extends KiwiSdrStream {
  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();
  final StreamController<Int16List> _controller = StreamController<Int16List>.broadcast();

  Stream<Int16List> get stream => _controller.stream;

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

    // Skip header (12 bytes) for waterfall data
    Uint8List compressedData = data.sublist(12);
    Int16List decodedSamples = _decoder.decode(compressedData);
    
    // Remove decompression tail
    decodedSamples = decodedSamples.sublist(0, decodedSamples.length - 10);

    _controller.sink.add(decodedSamples);
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
