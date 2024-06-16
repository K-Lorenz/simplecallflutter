import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static Future<void> initSupabase() async {
      Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: false,
    );
  }
  static Future<void> sendIceCandidate(Map<dynamic, String> data, String calleeId) async {
    Map<String, dynamic> candidate = {
      "callee_Id": calleeId,
      "caller_id": Supabase.instance.client.auth.currentUser!.id,
      "signal_type": "IceCandidate",
      "data": data
    };
    await Supabase.instance.client.from('Signaling').insert(candidate);
  }
  static Future<void> sendAnswer(Map<dynamic, String> answer, String calleeId) async {
    Map<String, dynamic> payload = {
      "caller_id": Supabase.instance.client.auth.currentUser!.id,
      "callee_Id": calleeId,
      "signal_type": "CallAnswer",
      "data": answer
    };
    await Supabase.instance.client.from('Signaling').insert(payload);
  }
  static Future<void> sendCall(String calleeId, Map<dynamic, String> sdpOffer) async {
    Map<String, dynamic> payload = {
      "callee_Id": calleeId,
      "caller_id": Supabase.instance.client.auth.currentUser!.id,
      "signal_type": "CallRequest",
      "data": sdpOffer
    };
    await Supabase.instance.client.from('Signaling').insert(payload);
  }
}