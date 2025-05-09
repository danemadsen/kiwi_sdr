part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrSoundStream extends KiwiSdrStream {
  static void worker((int, int, String, SendPort) args) async {
    final int versionMajor = args.$1;
    final int versionMinor = args.$2;
    final Uri url = Uri.parse(args.$3);
    final SendPort sendPort = args.$4;

    await KiwiSdrSoundStream(
      versionMajor: versionMajor,
      versionMinor: versionMinor,
      uri: url,
      sendPort: sendPort
    ).run();
  }

  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();
  final MovingAverageFilter _movingAverageFilter = MovingAverageFilter(5);

  @override
  String get tag => 'SND';
  
  KiwiSdrSoundStream({
    required super.versionMajor, 
    required super.versionMinor, 
    required super.uri,
    required super.sendPort,
  }) {
    setAuth('#');
    setCompression(true);
    setNoiseBlanker(100, 50);
    sendMessage('SET de_emp=0 nfm=1');
    sendMessage('SET little-endian');
  }

  @override
  dynamic parseData(Uint8List data) {
    if (!configLoaded) return null;

    Uint8List adpcmBytes = data.sublist(7);
    Int16List pcmSamples = _decoder.decode(adpcmBytes);
    Int16List resampledPcmSamples = PCM.resample(pcmSamples, 2);
    Int16List filteredPcmSamples = _movingAverageFilter.apply(resampledPcmSamples);

    // add the sample rate to the start of the samples
    final List<int> result = [(sampleRate * 2).toInt()];
    result.addAll(filteredPcmSamples);

    return Int16List.fromList(result);
  }

  @override
  void setCompression(bool enabled) => sendMessage('SET compression=${enabled ? 1 : 0}');

  @override
  void setupRxParams() {
    setMode(Modulation.am, -4900, 4900, 612.0);
    setAgc(1, 0, -100, 6, 1000, 50);
  }
}