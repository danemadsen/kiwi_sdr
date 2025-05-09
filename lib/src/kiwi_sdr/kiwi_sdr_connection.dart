part of 'package:flutter_sdr/flutter_sdr.dart';

class KiwiSdrConnection {
  final Isolate _soundIsolate;
  final Isolate _waterfallIsolate;
  final ReceivePort _soundReceivePort;
  final ReceivePort _waterfallReceivePort;
  final StreamController<Int16List> _soundStreamController = StreamController<Int16List>();
  final StreamController<Float32List> _waterfallStreamController = StreamController<Float32List>();

  Stream<Int16List> get soundStream => _soundStreamController.stream;

  Stream<Float32List> get waterfallStream => _waterfallStreamController.stream;

  KiwiSdrConnection._({
    required Isolate soundIsolate,
    required Isolate waterfallIsolate,
    required ReceivePort soundReceivePort,
    required ReceivePort waterfallReceivePort,
  }) :
    _soundIsolate = soundIsolate,
    _waterfallIsolate = waterfallIsolate,
    _soundReceivePort = soundReceivePort,
    _waterfallReceivePort = waterfallReceivePort {
    _soundReceivePort.listen(_soundStreamListener);

    _waterfallReceivePort.listen(_waterfallStreamListener);
  }

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

    final soundRecievePort = ReceivePort();

    final soundIsolate = await Isolate.spawn(
      KiwiSdrSoundStream.worker, 
      (maj, min, '$wsUrl/ws/kiwi/$ts/SND', soundRecievePort.sendPort)
    );

    final waterfallReceivePort = ReceivePort();

    final waterfallIsolate = await Isolate.spawn(
      KiwiSdrWaterfallStream.worker, 
      (maj, min, '$wsUrl/ws/kiwi/$ts/W/F', waterfallReceivePort.sendPort),
    );

    return KiwiSdrConnection._(
      soundIsolate: soundIsolate,
      waterfallIsolate: waterfallIsolate,
      soundReceivePort: soundRecievePort,
      waterfallReceivePort: waterfallReceivePort,
    );
  }

  void _soundStreamListener(dynamic data) {
    if (data is Int16List) {
      PCM.play(data.sublist(1), sampleRate: data[0].toDouble());
    }
  }

  void _waterfallStreamListener(dynamic data) {
    if (data is Float32List) {
      _waterfallStreamController.add(data);
    }
  }

  void close() {
    _soundIsolate.kill(priority: Isolate.immediate);
    _waterfallIsolate.kill(priority: Isolate.immediate);

    _soundReceivePort.close();
    _waterfallReceivePort.close();
  }
}
