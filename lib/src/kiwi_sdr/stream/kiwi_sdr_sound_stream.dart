import 'dart:typed_data';

import '../../utilities/ima_adpcm_decoder.dart';
import '../../utilities/moving_average_filter.dart';
import '../../sdr_mode.dart';
import '../../utilities/pcm.dart';
import 'kiwi_sdr_stream.dart';

class KiwiSdrSoundStream extends KiwiSdrStream {
  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();
  final MovingAverageFilter _movingAverageFilter = MovingAverageFilter(5);
  bool _playing = true;
  
  KiwiSdrSoundStream({
    required super.versionMajor, 
    required super.versionMinor, 
    required super.uri
  }) {
    setAuth('#');
    setCompression(true);
    setNoiseBlanker(100, 50);
    sendMessage('SET de_emp=0 nfm=1');
    sendMessage('SET little-endian');

    stream.listen(_onSoundData);
  }

  void _onSoundData(Uint8List data) {
    if (!_playing || !configLoaded) return;

    Uint8List adpcmBytes = data.sublist(7);
    Int16List pcmSamples = _decoder.decode(adpcmBytes);
    Int16List resampledPcmSamples = PCM.resample(pcmSamples, 2);
    Int16List filteredPcmSamples = _movingAverageFilter.apply(resampledPcmSamples);

    PCM.play(
      filteredPcmSamples,
      sampleRate: sampleRate * 2
    );
  }

  @override
  void setCompression(bool enabled) {
    sendMessage('SET compression=${enabled ? 1 : 0}');
  }

  @override
  void setupRxParams() {
    setMode(SdrMode.am, -4900, 4900, 612.0);
    setAgc(1, 0, -100, 6, 1000, 50);
  }

  void start() {
    _playing = true;
  }

  void stop() {
    _playing = false;
  }
}