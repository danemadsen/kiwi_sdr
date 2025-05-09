part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrConnection {
  final KiwiSdrSoundStream _soundStream;
  final KiwiSdrWaterfallStream _waterfallStream;

  KiwiSdrConnection({
    required KiwiSdrSoundStream soundStream, 
    required KiwiSdrWaterfallStream waterfallStream, 
  }) : 
  _soundStream = soundStream, 
  _waterfallStream = waterfallStream;

  static Future<KiwiSdrConnection> connect(String url) async {
    final versionResponse = await http.get(Uri.parse('$url/VER'));

    int maj, min, ts;
    if (versionResponse.statusCode == 200) {
      final versionData = jsonDecode(versionResponse.body);

      maj = versionData['maj'];
      min = versionData['min'];
      ts = versionData['ts'];
    } 
    else {
      throw KiwiSdrException('Failed get KiwiSDR version');
    }

    final wsUrl = url.replaceAll(RegExp(r'https?'), 'ws');

    final soundStream = KiwiSdrSoundStream(
      versionMajor: maj,
      versionMinor: min,
      uri: Uri.parse('$wsUrl/ws/kiwi/$ts/SND')
    );

    final waterfallStream = KiwiSdrWaterfallStream(
      versionMajor: maj,
      versionMinor: min,
      uri: Uri.parse('$wsUrl/ws/kiwi/$ts/W/F')
    );

    return KiwiSdrConnection(
      soundStream: soundStream,
      waterfallStream: waterfallStream
    );
  }

  void close() {
    _soundStream.close();
    _waterfallStream.close();
  }
}
