part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrConnection {
  final KiwiSdrSoundStream _soundStream;
  final KiwiSdrWaterfallStream _waterfallStream;
  final KiwiSdrExtensionStream _extensionStream;

  KiwiSdrConnection({
    required KiwiSdrSoundStream soundStream, 
    required KiwiSdrWaterfallStream waterfallStream, 
    required KiwiSdrExtensionStream extensionStream
  }) : 
  _soundStream = soundStream, 
  _waterfallStream = waterfallStream, 
  _extensionStream = extensionStream;

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
      throw Exception('Failed get KiwiSDR version');
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

    final extensionStream = KiwiSdrExtensionStream(
      versionMajor: maj,
      versionMinor: min,
      uri: Uri.parse('$wsUrl/ws/kiwi/$ts/EXT')
    );

    return KiwiSdrConnection(
      soundStream: soundStream,
      waterfallStream: waterfallStream,
      extensionStream: extensionStream
    );
  }

  void start() {
    _soundStream.start();
  }

  void stop() {
    _soundStream.stop();
  }

  void close() {
    _soundStream.close();
    _waterfallStream.close();
    _extensionStream.close();
  }

  Stream<Float32List> get waterfallStream => _waterfallStream.stream;
}
