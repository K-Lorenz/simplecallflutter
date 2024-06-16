// ignore_for_file: dead_code

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:simplecallflutter/utils/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebRTCUtil {
   RTCPeerConnection? _peerConnection;
   MediaStream? _localStream;
   List<RTCIceCandidate> _iceCandidates = [];
   final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302']
      }
    ]
  };
  Future<void> initWebRTC(String calleeId, [dynamic incomingOffer]) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    _peerConnection = await createPeerConnection(_configuration);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
    //True for incoming calls, False for outgoing calls
    if(incomingOffer!=null){
      Supabase.instance.client
        .channel("IceCandidates")
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Signaling',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'calleeId', value: Supabase.instance.client.auth.currentUser!.id),
          callback: (payload){
            if(payload.newRecord['signal_type']=="IceCandidate"){
              String candidate =payload.newRecord["data"]['candidate'];
              String sdpMid =  payload.newRecord["data"]['id'];
              int sdpMLineIndex = payload.newRecord["data"]['label'];
              _peerConnection!.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
            }
          })
        .subscribe();

      await _peerConnection!.setRemoteDescription(RTCSessionDescription(incomingOffer["sdp"], incomingOffer["type"]));
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      _peerConnection!.setLocalDescription(answer);
      SupabaseService.sendAnswer(answer.toMap(),calleeId);

    }else{
        _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) => _iceCandidates.add(candidate);
        Supabase.instance.client.channel("callAnswered").onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Signaling',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'calleeId', value: Supabase.instance.client.auth.currentUser!.id),
          callback: (payload)async{
            if(payload.newRecord['signal_type']=="CallAnswer") {
              await _peerConnection!.setRemoteDescription(RTCSessionDescription(payload.newRecord['data']['sdp'], payload.newRecord['data']['sdp']));
              for(RTCIceCandidate candidate in _iceCandidates){
                await Supabase.instance.client.from('Signaling').insert({
                "caller_id": Supabase.instance.client.auth.currentUser!.id,
                "callee_id": calleeId,
                "signal_type": "IceCandidate",
                "data": {
                  "id": candidate.sdpMid,
                  "label": candidate.sdpMLineIndex,
                  "candidate": candidate.candidate
                }
              });
              }
              
            }
          }
        ).subscribe();

        RTCSessionDescription offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        print("hola");
        await Supabase.instance.client.from('Signaling').insert({
          "callee_id": calleeId,
          "caller_id": Supabase.instance.client.auth.currentUser!.id,
          "signal_type": "CallRequest",
          "data": offer.toMap()
        });
    }
  }
}