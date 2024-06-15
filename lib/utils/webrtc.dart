import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:simplecallflutter/utils/supabase_service.dart';

class WebRTCUtil {
  static late RTCPeerConnection _peerConnection;
  static late MediaStream _localStream;
  static final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302']
      }
    ]
  };
  static Future<void> initWebRTC() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection.onIceCandidate = (candidate) {
      //send candidate to other peer via supabase
      if (candidate != null) {
        final candidateJson = candidate.toMap();
      }
    };
    _peerConnection.onTrack = (event) {
      //handle remote stream
    };

    _localStream.getTracks().forEach((track) {
      _peerConnection.addTrack(track, _localStream);
    });
  }
  static Future<void> createOffer() async {
    final offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);
    //send offer to other peer via supabase
  }

  static void dispose() {
    _localStream.dispose();
    _peerConnection.dispose();
  }

  static void handleSignalingMessages(){
    //listen to signaling messages from supabase
  }
}