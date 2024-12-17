import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:developer' as developer;

import '../../sdr_mode.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class KiwiSdrStream {
  static const int _maxZoom = 14;
  static const int _wfBins = 1024;

  final WebSocketChannel _socket;
  final StreamController<Uint8List> _streamController = StreamController<Uint8List>.broadcast();

  int _versionMajor;
  int _versionMinor;

  bool configLoaded = false;
  bool noiseBlanker = true;
  bool _keepAlive = true;

  //double _centerFrequency = 15e5;
  double _maxFrequency = 30e5;
  SdrMode _mode = SdrMode.am;
  double? _sampleRate;
  int? _numChannels;
  int? _lowCut;
  int? _highCut;
  double? _frequency;
  double? _frequencyOffset;

  SdrMode get mode => _mode;

  double get sampleRate => _sampleRate!;

  double get kiwiVersion => _versionMajor + _versionMinor / 1000;

  int get numChannels => _numChannels!;

  int get lowCut => _lowCut!;

  int get highCut => _highCut!;

  double get frequency => _frequency!;

  Stream<Uint8List> get stream => _streamController.stream;

  KiwiSdrStream({
    required int versionMajor, 
    required int versionMinor, 
    required Uri uri
  }) : 
    _socket = WebSocketChannel.connect(uri), 
    _versionMajor = versionMajor, 
    _versionMinor = versionMinor 
  {
    _socket.stream.listen(_onChannelData);

    Timer.periodic(
      const Duration(seconds: 5), 
      _keepAliveTimer
    );
  }

  void _onChannelData(dynamic data) {
    final tag = String.fromCharCodes(data.sublist(0, 3));
    final Uint8List value = data.sublist(3);

    switch (tag) {
      case 'SND':
        _streamController.sink.add(value);
        break;
      case 'MSG':
        final message = String.fromCharCodes(value);
        _parseMessage(message);
        break;
      default:
        developer.log('Unknown tag: $tag');
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
        setArOk(int.parse(value), 48000);
        break;
      case 'sample_rate':
        _sampleRate = double.parse(value);
        setSquelch(0, 0);
        setGen(0, 0);
        setupRxParams();
        setKeepAlive();
        break;
      case 'wf_setup':
        setupRxParams();
        setKeepAlive();
        break;
      case 'rx_chans':
        _numChannels = int.parse(value);
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
      //case 'center_freq':
      //  _centerFrequency = double.parse(value);
      //  break;
      case 'bandwidth':
        _maxFrequency = double.parse(value) / 1000;
        break;
      case 'cfg_loaded':
        configLoaded = true;
        break;
      case 'too_busy':
        throw Exception('KiwiSDR too busy. All $value client slots are in use.');
      case 'redirect':
        throw Exception('KiwiSDR redirect to ${Uri.decodeComponent(value)}');
      case 'badp':
        switch (value) {
          case '0':
            break;
          case '1':
            throw Exception('KiwiSDR bad password');
          case '5':
            throw Exception('KiwiSDR multiple connections from the same IP address');
          default:
            throw Exception('KiwiSDR password error: $value');
        }
        break;
      case 'down':
        throw Exception('KiwiSDR is down');
    }
  }

  void _keepAliveTimer(Timer timer) {
    if (_keepAlive) {
      setKeepAlive();
    } 
    else {
      timer.cancel();
    }
  }

  void close() {
    _keepAlive = false;
    _socket.sink.close();
    _streamController.sink.close();
  }

  void sendMessage(String message) {
    _socket.sink.add(message);
  }

  void setKeepAlive() {
    sendMessage('SET keepalive');
  }

  void setFrequency(double freq) {
    _frequency = freq;

    if ([SdrMode.am, SdrMode.amn, SdrMode.amw].contains(_mode)) {
      if (_highCut != null) {
        _lowCut = -_highCut!;
      }
      else {
        _lowCut = null;
      }
    }

    setMode(_mode, _lowCut, _highCut, freq);
  }

  void setMode(SdrMode mode, int? lc, int? hc, double freq) {
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

    _frequency = freq;

    double basebandFrequency = freq;
    if (_frequencyOffset != null) {
      basebandFrequency -= _frequencyOffset!;
    }

    sendMessage('SET mod=${mode.name} low_cut=$_lowCut high_cut=$_highCut freq=$basebandFrequency');
  }

  void setupRxParams();

  void setAgc(int on, int hang, int threshold, int slope, int decay, int gain) {
    sendMessage('SET agc=$on hang=$hang thresh=$threshold slope=$slope decay=$decay manGain=$gain');
  }

  void setSquelch(int squelch, int threshold) {
    sendMessage('SET squelch=$squelch max=$threshold');
  }

  void setArOk(int inRate, int outRate) {
    sendMessage('SET AR OK in=$inRate out=$outRate');
  }

  void setGen(int freq, int attn) {
    sendMessage('SET genattn=$attn');
    sendMessage('SET gen=$freq mix=-1');
  }

  void setZoomCf(int zoom, double cfkHz) {
    if (kiwiVersion > 1.329) {
      sendMessage('SET zoom=$zoom cf=$cfkHz');
    }
    else {
      final startFrequency = cfkHz - zoomToSpan(zoom) / 2;
      final counter = startFrequencyToCounter(startFrequency);
      sendMessage('SET zoom=$zoom start=$counter');
    }
  }

  double zoomToSpan(int zoom) {
    if (zoom <= 0 || zoom > _maxZoom) {
      throw Exception('Invalid zoom level: $zoom');
    }

    return _maxFrequency / pow(2, zoom);
  }

  int startFrequencyToCounter(double startFrequency) {
    return (startFrequency / _maxFrequency * pow(2, _maxZoom) * _wfBins).round();
  }

  void setMaxDbMinDb(int maxDb, int minDb) {
    sendMessage('SET maxdb=$maxDb mindb=$minDb');
  }

  void setWfSpeed(int speed) {
    speed = max(1, min(4, speed)); // clamp to 1-4

    sendMessage('SET wf_speed=$speed');
  }

  void setWfInterp(int interp) {
    if (interp == -1) {
      interp = 13;
    }

    if ((interp < 0 || interp > 4) && (interp < 10 || interp > 14)) {
      throw Exception('Invalid interp value: $interp');
    }

    sendMessage('SET interp=$interp');
  }

  void setWindowFunc(int windowFunc) {
    sendMessage('SET window_func=$windowFunc');
  }

  void setAuth(String token) {
    sendMessage('SET auth t=kiwi p=$token');
  }

  void setName(String name) {
    sendMessage('SET ident_user=$name');
  }

  void setGeo(String geo) {
    sendMessage('SET geo=$geo');
  }

  void setCompression(bool enabled);

  void setNoiseBlanker(int gate, int threshold) {
    sendMessage('SET nb algo=1');
    sendMessage('SET nb type=0 param=0 pval=$gate');
    sendMessage('SET nb type=0 param=1 pval=$threshold');
    sendMessage('SET nb type=0 en=${noiseBlanker ? 1 : 0}');
    sendMessage('SET nb type=2 param=0 pval=1');
    sendMessage('SET nb type=2 param=1 pval=1');
    sendMessage('SET nb type=2 en=0');
  }
}