part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrSoundStream extends KiwiSdrStream {
  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();

  @override
  String get tag => 'SND';
  
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
  }

  @override
  void acceptData(Uint8List data) async {
    if (!configLoaded) return;

    Uint8List adpcmBytes = data.sublist(7);
    
    Uint8List pcmSamples = _decoder.decode(adpcmBytes);

    // Create WAV file bytes
    final bytes = _createWavFile(pcmSamples, sampleRate, 1, 16);
  
    final audioPlayer = AudioPlayer();

    // Play the WAV file
    await audioPlayer.play(
      BytesSource(bytes, mimeType: 'audio/wav'),
      mode: PlayerMode.lowLatency,
    );

    await audioPlayer.onPlayerComplete.first;

    audioPlayer.dispose();
  }

  @override
  void setCompression(bool enabled) => sendMessage('SET compression=${enabled ? 1 : 0}');

  @override
  void setupRxParams() {
    setMode(Modulation.am, -4900, 4900, 612.0);
    setAgc(1, 0, -100, 6, 1000, 50);
  }

  Uint8List _createWavFile(Uint8List pcmData, double sampleRate, int channels, int bitDepth) {
    int byteRate = sampleRate * channels * bitDepth ~/ 8;
    int blockAlign = channels * bitDepth ~/ 8;
    int fileSize = 36 + pcmData.length;
  
    ByteData header = ByteData(44);
  
    // RIFF header
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, fileSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
  
    // fmt subchunk
    header.setUint32(12, 0x666d7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // PCM format chunk size
    header.setUint16(20, 1, Endian.little); // Audio format (1 = PCM)
    header.setUint16(22, channels, Endian.little); // Number of channels
    header.setUint32(24, sampleRate.round(), Endian.little); // Sample rate
    header.setUint32(28, byteRate, Endian.little); // Byte rate
    header.setUint16(32, blockAlign, Endian.little); // Block align
    header.setUint16(34, bitDepth, Endian.little); // Bits per sample
  
    // data subchunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, pcmData.length, Endian.little); // PCM data size
  
    // Combine header and PCM data
    return Uint8List.fromList(header.buffer.asUint8List() + pcmData);
  }
}