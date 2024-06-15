

import 'dart:convert';

import 'package:postgrest/src/types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplecallflutter/utils/supabase_service.dart';

class User{


  static Future<void> login() async{
    final prefs = await SharedPreferences.getInstance();
    var sessionString = prefs.getString("session");
    if(sessionString == null){
      await SupabaseService.supabaseClient.auth.signInAnonymously().then((value) async {
        await prefs.setString("session", jsonEncode(value.session));
        await SupabaseService.supabaseClient.from('Profiles').insert([{'id': value.user!.id}]).select().then((value) async{
          await prefs.setString("profile", jsonEncode(value[0]));
        }).catchError((error){
          print(error);
        });
      }).catchError((error){
        print(error);
      });

    }else{
      SupabaseService.supabaseClient.auth.recoverSession(sessionString).then((value)async {
        await prefs.setString("session",  jsonEncode(value.session));
      }).catchError((error){
        print(error);
      });
      Map<String, dynamic> sessionJson = jsonDecode(sessionString);
      SupabaseService.supabaseClient.from('Profiles').select('*').eq('id',sessionJson['user']['id']).limit(1).then((value) async{
        await prefs.setString("profile", jsonEncode(value[0]));
      }).catchError((error){
        print(error + "EERRROOOOORR");
      });
    }
  }
  static Future<List<Map<String, dynamic>>> getConnectionProfiles() async{
    final prefs = await SharedPreferences.getInstance();
    var ids = <dynamic>[];
    Map<String, dynamic> profileJson = jsonDecode(prefs.getString("profile")!);
    var main = profileJson['type'] == 'Caretaker' ? 'caretaker_id' : 'senior_id';
    var other = profileJson['type'] == 'Caretaker' ? 'senior_id' : 'caretaker_id';
    await SupabaseService.supabaseClient.from('Connections').select(other).eq(main, profileJson['id']).then((value){
      ids.addAll(value.map((e) => e[other].toString()));
    }).catchError((error){
      print(error);
    });
    return SupabaseService.supabaseClient.from('Profiles').select('*').inFilter('id', ids).then((value){
      return value;
    }).catchError((error){
      print(error);
    });
  }

}