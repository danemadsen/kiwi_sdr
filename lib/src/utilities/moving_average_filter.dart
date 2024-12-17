import 'dart:typed_data';

class MovingAverageFilter {
  final int windowSize;
  final List<int> _buffer;
  int _bufferIndex = 0;

  MovingAverageFilter(this.windowSize) : _buffer = List<int>.filled(windowSize, 0);

  Int16List apply(Int16List pcmSamples) {
    Int16List filteredSamples = Int16List(pcmSamples.length);
    for (int i = 0; i < pcmSamples.length; i++) {
      // Add the current sample to the circular buffer
      _buffer[_bufferIndex] = pcmSamples[i];
      _bufferIndex = (_bufferIndex + 1) % windowSize;

      // Calculate the moving average
      int sum = 0;
      for (int j = 0; j < windowSize; j++) {
        sum += _buffer[j];
      }
      filteredSamples[i] = sum ~/ windowSize;
    }

    return filteredSamples;
  }
}