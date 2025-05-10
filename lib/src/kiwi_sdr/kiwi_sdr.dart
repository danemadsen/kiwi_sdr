part of 'package:kiwi_sdr/kiwi_sdr.dart';

class KiwiSDR {
  final StreamController<Float32List> _streamController = StreamController.broadcast();
  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();

  final WebSocketChannel _soundSocket;
  final WebSocketChannel _waterfallSocket;

  int _versionMajor;
  int _versionMinor;

  double get _kiwiVersion => _versionMajor + _versionMinor / 1000;

  bool _configLoaded = false;
  bool _keepAlive = true;

  Modulation _mode;
  double? _maxFrequency;
  int? _maxZoom;
  int? _fftSize;
  double? _sampleRate;
  int? _lowCut;
  int? _highCut;
  double? _frequency;
  double? _frequencyOffset;

  Stream<Float32List> get waterfallStream => _streamController.stream;

  KiwiSDR._({
    required int versionMajor,
    required int versionMinor,
    required WebSocketChannel soundSocket,
    required WebSocketChannel waterfallSocket,
    required Modulation mode,
  }) :
    _versionMajor = versionMajor,
    _versionMinor = versionMinor,
    _soundSocket = soundSocket,
    _waterfallSocket = waterfallSocket,
    _mode = mode {
    setAuthentication('#');
    setSoundCompression(true);
    setNoiseBlanker(100, 50, true);
    _soundSocket.sink.add('SET de_emp=0 nfm=1');
    _soundSocket.sink.add('SET little-endian');

    Timer.periodic(
      const Duration(seconds: 5), 
      _keepAliveTimer
    );

    _soundSocket.stream.listen(_onSocketData);
    _waterfallSocket.stream.listen(_onSocketData);
  }

  static Future<KiwiSDR> connect(String url, [Modulation mode = Modulation.am]) async {
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

    final soundSocket = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/kiwi/$ts/SND')
    );

    final waterfallSocket = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/kiwi/$ts/W/F')
    );

    return KiwiSDR._(
      versionMajor: maj,
      versionMinor: min,
      soundSocket: soundSocket,
      waterfallSocket: waterfallSocket,
      mode: mode,
    );
  }

  void _onSocketData(dynamic data) {
    final dataTag = String.fromCharCodes(data.sublist(0, 3));
    final Uint8List value = data.sublist(3);

    if (dataTag == 'MSG') {
      final message = String.fromCharCodes(value);
      _parseMessage(message);
    }
    else if (dataTag == 'SND'){
      _processSoundData(value);
    }
    else if (dataTag == 'W/F'){
      _processWaterfallData(value);
    }
  }

  void _parseMessage(String message) {
    for (final property in message.split(' ')) {
      final parts = property.split('=');
      if (parts.length == 2) {
        _parseProperty(parts[0], parts[1]);
      }
      else {
        _parseProperty(property, '');
      }
    }
  }

  void _parseProperty(String key, String value) {
    switch (key) {
      case 'audio_rate':
        setAudioRate(int.parse(value), 48000);
        break;
      case 'sample_rate':
        _sampleRate = double.parse(value);
        setSquelch(0, 0);
        setGen(0, 0);
        _setupSoundParams();
        _setKeepAlive();
        break;
      case 'wf_setup':
        _setupWaterfallParams();
        _setKeepAlive();
        break;
      case 'zoom_max': 
        _maxZoom = int.parse(value);
        break;
      case 'wf_fft_size':
        _fftSize = int.parse(value);
        break;
      case 'version_maj':
        _versionMajor = int.parse(value);
        break;
      case 'version_min':
        _versionMinor = int.parse(value);
        break;
      case 'freq_offset':
        _frequencyOffset = double.parse(value);
        break;
      case 'bandwidth':
        _maxFrequency = double.parse(value) / 1000;
        break;
      case 'cfg_loaded':
        _configLoaded = true;
        break;
      case 'too_busy':
        throw KiwiSdrException('KiwiSDR too busy. All $value client slots are in use.');
      case 'redirect':
        throw KiwiSdrException('KiwiSDR redirect to ${Uri.decodeComponent(value)}');
      case 'badp':
        switch (value) {
          case '0':
            break;
          case '1':
            throw KiwiSdrException('KiwiSDR bad password');
          case '5':
            throw KiwiSdrException('KiwiSDR multiple connections from the same IP address');
          default:
            throw KiwiSdrException('KiwiSDR password error: $value');
        }
        break;
      case 'down':
        throw KiwiSdrException('KiwiSDR is down');
    }
  }

  void _processSoundData(Uint8List data) async {
    if (!_configLoaded) return;

    Uint8List adpcmBytes = data.sublist(7);
    
    Uint8List pcmSamples = _decoder.decode(adpcmBytes);

    // Create WAV file bytes
    final bytes = _createWavFile(pcmSamples, _sampleRate!, 1, 16);
  
    final audioPlayer = AudioPlayer();

    // Play the WAV file
    await audioPlayer.play(
      BytesSource(bytes, mimeType: 'audio/wav'),
      mode: PlayerMode.lowLatency,
    );

    await audioPlayer.onPlayerComplete.first;

    audioPlayer.dispose();
  }

  void _processWaterfallData(Uint8List data) {
    if (!_configLoaded) return;

    // Skip header (14 bytes)
    final waterfallData = data.sublist(14);

    final min = waterfallData.reduce((a, b) => a < b ? a : b);
    final max = waterfallData.reduce((a, b) => a > b ? a : b);
    final fifty = (max - min) / 3;
    final range = (max - (min + fifty)).toDouble().clamp(1.0, double.infinity); // Avoid div by 0
    final Float32List output = Float32List(waterfallData.length);

    for (int i = 0; i < waterfallData.length; i++) {
      final normalized = (waterfallData[i] - (min + fifty)) / range;
      output[i] = normalized.clamp(0.0, 1.0);
    }

    _streamController.add(output);
  }

  void _broadcastMessage(String message) {
    _soundSocket.sink.add(message);
    _waterfallSocket.sink.add(message);
  }

  void _setKeepAlive() => _broadcastMessage('SET keepalive');

  void _keepAliveTimer(Timer timer) {
    if (_keepAlive) {
      _setKeepAlive();
    } 
    else {
      timer.cancel();
    }
  }

  void _setupSoundParams() {
    setModulation(Modulation.am, hc: -4900, lc: 4900, frequency: 612.0);
    setAgc(1, 0, -100, 6, 1000, 50);
  }

  void _setupWaterfallParams() {
    setZoomCf(0, 0);
    setMaxDbMinDb(-10, -110);
    setWaterfallSpeed(4);
    setWaterfallInterp(13);
  }

  void setAgc(
    int on, 
    int hang, 
    int threshold, 
    int slope, 
    int decay, 
    int gain
  ) => _soundSocket.sink.add('SET agc=$on hang=$hang thresh=$threshold slope=$slope decay=$decay manGain=$gain');

  void setAudioRate(int inRate, int outRate) => _soundSocket.sink.add('SET AR OK in=$inRate out=$outRate');

  void setSquelch(int squelch, int threshold) => _soundSocket.sink.add('SET squelch=$squelch max=$threshold');

  void setGen(int freq, int attn) {
    _broadcastMessage('SET genattn=$attn');
    _broadcastMessage('SET gen=$freq mix=-1');
  }

  void setFrequency(double frequency) {
    _frequency = frequency;

    setModulation(_mode, frequency: frequency);
  }

  void setModulation(Modulation mode, {int? lc, int? hc, double? frequency}) {
    _mode = mode;
    
    if (lc != null) {
      _lowCut = lc;
    }
    else {
      _lowCut = mode.lc;
    }

    if (hc != null) {
      _highCut = hc;
    }
    else {
      _highCut = mode.hc;
    }

    if (frequency != null) {
      _frequency = frequency;
    }
    else {
      _frequency ??= 0.0;
    }

    double freq = _frequency!;
    if (_frequencyOffset != null) {
      freq -= _frequencyOffset!;
    }

    _soundSocket.sink.add('SET mod=${mode.name} low_cut=$_lowCut high_cut=$_highCut freq=$freq');
  }

  void setZoomCf(int zoom, double cfkHz) {
    if (_kiwiVersion > 1.329) {
      _waterfallSocket.sink.add('SET zoom=$zoom cf=$cfkHz');
    }
    else if (zoom <= 0 || zoom > (_maxZoom ?? 14)) {
      throw KiwiSdrException('Invalid zoom level: $zoom');
    }
    else {
      final startFrequency = cfkHz - (_maxFrequency! / pow(2, zoom)) / 2;
      final counter = (startFrequency / _maxFrequency! * pow(2, _maxZoom ?? 14) * (_fftSize ?? 1024)).round();
      _waterfallSocket.sink.add('SET zoom=$zoom start=$counter');
    }
  }

  void setMaxDbMinDb(int maxDb, int minDb) => _waterfallSocket.sink.add('SET maxdb=$maxDb mindb=$minDb');

  void setWaterfallSpeed(int speed) {
    speed = max(1, min(4, speed)); // clamp to 1-4

    _waterfallSocket.sink.add('SET wf_speed=$speed');
  }

  void setWaterfallInterp(int interp) {
    if (interp == -1) {
      interp = 13;
    }

    if ((interp < 0 || interp > 4) && (interp < 10 || interp > 14)) {
      throw KiwiSdrException('Invalid interp value: $interp');
    }

    _waterfallSocket.sink.add('SET interp=$interp');
  }

  void setWindowFunc(int windowFunc) => _broadcastMessage('SET window_func=$windowFunc');

  void setAuthentication(String token) => _broadcastMessage('SET auth t=kiwi p=$token');

  void setUserName(String name) => _broadcastMessage('SET ident_user=$name');

  void setGeolocation(String geo) => _broadcastMessage('SET geo=$geo');

  void setSoundCompression(bool enabled) => _soundSocket.sink.add('SET compression=${enabled ? 1 : 0}');

  void setWaterfallCompression(bool enabled) => _waterfallSocket.sink.add('SET wf_comp=${enabled ? 1 : 0}');

  void setNoiseBlanker(int gate, int threshold, bool noiseBlanker) {
    _soundSocket.sink.add('SET nb algo=1');
    _soundSocket.sink.add('SET nb type=0 param=0 pval=$gate');
    _soundSocket.sink.add('SET nb type=0 param=1 pval=$threshold');
    _soundSocket.sink.add('SET nb type=0 en=${noiseBlanker ? 1 : 0}');
    _soundSocket.sink.add('SET nb type=2 param=0 pval=1');
    _soundSocket.sink.add('SET nb type=2 param=1 pval=1');
    _soundSocket.sink.add('SET nb type=2 en=0');
  }

  void close() {
    _keepAlive = false;
    _soundSocket.sink.close();
    _waterfallSocket.sink.close();
  }
}