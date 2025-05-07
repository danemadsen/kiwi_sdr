part of 'package:flutter_sdr/flutter_sdr.dart';

const List<int> _stepSizeTable = [
  7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41,
  45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190,
  209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
  876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499,
  2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845,
  8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385,
  24623, 27086, 29794, 32767
];

const List<int> _indexAdjustTable = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8];

class ImaAdpcmDecoder {
  int _index = 0;
  int _prev = 0;

  int _decodeSample(int code) {
    int step = _stepSizeTable[_index];
    _index = (_index + _indexAdjustTable[code]).clamp(0, _stepSizeTable.length - 1);
    int difference = step >> 3;
    if ((code & 1) != 0) difference += step >> 2;
    if ((code & 2) != 0) difference += step >> 1;
    if ((code & 4) != 0) difference += step;
    if ((code & 8) != 0) difference = -difference;

    int sample = (_prev + difference).clamp(-32768, 32767);
    _prev = sample;
    return sample;
  }

  Int16List decode(Uint8List data) {
    List<int> samples = [];
    for (final byte in data) {
      int sample0 = _decodeSample(byte & 0x0F);
      int sample1 = _decodeSample(byte >> 4);
      samples.add(sample0);
      samples.add(sample1);
    }
    return Int16List.fromList(samples);
  }
}
