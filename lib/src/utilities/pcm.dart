part of 'package:flutter_sdr/flutter_sdr.dart';

class PCM {
  static Int16List resample(Int16List pcmSamples, double ratio) {
    int newLength = (pcmSamples.length * ratio).toInt();
    Int16List resampled = Int16List(newLength);
  
    // Find the maximum value in the original samples for normalization
    int maxSampleValue = pcmSamples.reduce((a, b) => a > b ? a : b);
    
    // DC Offset Correction: Calculate the average of the PCM samples and subtract it
    double avgSampleValue = pcmSamples.fold(0, (sum, sample) => sum + sample) / pcmSamples.length;
  
    for (int i = 0; i < newLength; i++) {
      // Calculate the original index in the input sample set
      double originalIndex = i / ratio;
      int indexBefore = originalIndex.floor();
      int indexAfter = originalIndex.ceil();
  
      if (indexAfter >= pcmSamples.length) {
        indexAfter = pcmSamples.length - 1;
      }
  
      // Apply cubic interpolation
      double t = originalIndex - indexBefore;
  
      int s0 = indexBefore > 0 ? pcmSamples[indexBefore - 1] : pcmSamples[indexBefore];
      int s1 = pcmSamples[indexBefore];
      int s2 = pcmSamples[indexAfter];
      int s3 = indexAfter < pcmSamples.length - 1 ? pcmSamples[indexAfter + 1] : pcmSamples[indexAfter];
  
      int a0 = s3 - s2 - s0 + s1;
      int a1 = s0 - s1 - a0;
      int a2 = s2 - s0;
      int a3 = s1;
  
      double interpolatedValue = (a0 * t * t * t) + (a1 * t * t) + (a2 * t) + a3;
  
      // Normalize the interpolated value and remove DC offset
      double normalizedValue = (interpolatedValue - avgSampleValue) / maxSampleValue * 32767;
  
      // Clamp the value to avoid clipping
      normalizedValue = normalizedValue.clamp(-32768, 32767);
  
      resampled[i] = normalizedValue.toInt();
    }
  
    return resampled;
  }

  static Future<void> play(Int16List pcmSamples, {double sampleRate = 16000, int channels = 1, int bitDepth = 16}) async {
    // Convert Int16List to Uint8List
    Uint8List pcmData = pcmSamples.buffer.asUint8List();
  
    final bytes = _createWavFile(pcmData, sampleRate, channels, bitDepth);
  
    // Play the WAV file
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(
      BytesSource(bytes, mimeType: 'audio/wav'),
      mode: PlayerMode.lowLatency,
    );

    // Wait for the audio to finish playing
    await audioPlayer.onPlayerComplete.first;

    // Delay for a second to ensure the audio is finished playing
    await Future.delayed(const Duration(seconds: 1));
  }
  
  // Function to create WAV file bytes from PCM data
  static Uint8List _createWavFile(Uint8List pcmData, double sampleRate, int channels, int bitDepth) {
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