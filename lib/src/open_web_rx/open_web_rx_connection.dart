import 'dart:developer';
import 'dart:typed_data';

import '../sdr_connection.dart';
import '../utilities/ima_adpcm_decoder.dart';
import '../utilities/moving_average_filter.dart';
import '../utilities/pcm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OpenWebRxConnection extends SdrConnection {
  final ImaAdpcmDecoder _decoder = ImaAdpcmDecoder();
  final MovingAverageFilter _movingAverageFilter = MovingAverageFilter(5);
  final WebSocketChannel _socket;
  bool _playing = true;

  OpenWebRxConnection({
    required WebSocketChannel socket
  }) : _socket = socket {
    _sendMessage('SERVER DE CLIENT client=openwebrx.js type=receiver');
    _sendMessage('{"type":"connectionproperties","params":{"output_rate":11025,"hd_output_rate":44100}}');
    _sendMessage('{"type":"dspcontrol","params":{"low_cut":-4900,"high_cut":4900,"offset_freq":-488000,"mod":"am","dmr_filter":3,"audio_service_id":0,"squelch_level":-150,"secondary_mod":false}}');
    _sendMessage('{"type":"dspcontrol","params":{"offset_freq":-488000}}');
    _sendMessage('{"type":"dspcontrol","action":"start"}');
    
    _socket.stream.listen(_onChannelData);
  }

  static Future<OpenWebRxConnection> connect(String url) async {
    final wsUrl = url.replaceAll(RegExp(r'https?'), 'ws');

    log('Connecting to $wsUrl/ws/');

    final socket = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/'));

    return OpenWebRxConnection(socket: socket);
  }

  void _onChannelData(dynamic data) {
    final flag = data[0];
    switch (flag) {
      case 1:
        log('FFT data');
        break;
      case 2:
        log('Sound data');
        _onSoundData(data);
        break;
      default:
        log('Data: $data');
    }
  }

  void _onSoundData(Uint8List data) {
    if (!_playing) return;

    Uint8List adpcmBytes = data.sublist(1);
    Int16List pcmSamples = _decoder.decode(adpcmBytes);
    Int16List resampledPcmSamples = PCM.resample(pcmSamples, 2);
    Int16List filteredPcmSamples = _movingAverageFilter.apply(resampledPcmSamples);

    PCM.play(
      filteredPcmSamples,
      sampleRate: 11025 * 2
    );
  }

  void _sendMessage(String message) {
    _socket.sink.add(message);
  }
  
  @override
  void start() {
    _playing = true;
  }

  @override
  void stop() {
    _playing = false;
  }

  @override
  void close() {
    _socket.sink.close();
  }
}