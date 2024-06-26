

import 'dart:convert';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplecallflutter/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManager{

  static Future<void> login() async{
    final prefs = await SharedPreferences.getInstance();
      await Supabase.instance.client.auth.signInAnonymously().then((value) async {
        if(prefs.get("profile")==null){
          await Supabase.instance.client.from('Profiles').insert([{'id': value.user!.id}]).select().then((value) async{
          await prefs.setString("profile", jsonEncode(value[0]));
        }).catchError((error){
          print(error);
        });
        }
      }).catchError((error){
        print(error);
      });
      subscribeToProfile();
  }
  static void subscribeToProfile(){
    print(Supabase.instance.client.auth.currentUser!.id);
    Supabase.instance.client
      .channel('yadada')
      .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'Profiles',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: Supabase.instance.client.auth.currentUser!.id),
          callback: (payload) async{
            await prefs.setString("profile", jsonEncode(payload.newRecord));
          })
      .subscribe();
    print("test2");
  }

  static Future<List<Map<String, dynamic>>> getConnectionProfiles() async{
    final prefs = await SharedPreferences.getInstance();
    var ids = <dynamic>[];
    Map<String, dynamic> profileJson = jsonDecode(prefs.getString("profile")!);
    var main = profileJson['type'] == 'Caretaker' ? 'caretaker_id' : 'senior_id';
    var other = profileJson['type'] == 'Caretaker' ? 'senior_id' : 'caretaker_id';
    await Supabase.instance.client.from('Connections').select(other).eq(main, profileJson['id']).then((value){
      print(value);
      ids.addAll(value.map((e) => e[other].toString()));
    }).catchError((error){
      print(error);
    });
    return Supabase.instance.client.from('Profiles').select('*').inFilter('id', ids).then((value){
      return value;
    }).catchError((error){
      print(error);
    });
  }
  static Future<void> createConnection(String connectCode) async{
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> profileJson = jsonDecode(prefs.getString("profile")!);
    var senior_id = await Supabase.instance.client.from('Profiles').select('id').eq('connect_string', connectCode).then((value){
      return value[0]['id'];
    }).catchError((error){
      print(error);
    });
    await Supabase.instance.client.from('Connections').insert([{"caretaker_id": profileJson['id'], "senior_id": senior_id}]).then((value){
      print(value);
    }).catchError((error){
      print(error);
    });
  }
  static Future<void> updateUser(String fullName, XFile avatar) async{
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> profileJson = jsonDecode(prefs.getString("profile")!);
    var avatarUrl = "";
      final bytes = await avatar.readAsBytes();
      final fileExt = avatar.path.split('.').last;
      final random  = Random().nextInt(9999999);
      final fileName = '${profileJson['id']}$random.$fileExt';
      await Supabase.instance.client.storage.from('avatars').uploadBinary(fileName, bytes, fileOptions: FileOptions(contentType: avatar.mimeType)).then((value){
        print(value);
      }).catchError((error){
        print(error);
      });
      avatarUrl = await Supabase.instance.client.storage.from('avatars').createSignedUrl(fileName, 60*60*24*365*10);
      //upload image to storage
      //get url
    await Supabase.instance.client.from('Profiles').update({"full_name": fullName, "avatar_url": avatarUrl}).eq('id', profileJson['id']).then((value){
      print(value);
    }).catchError((error){
      print(error);
    });
  }
  static Future<void> swapType() async{
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> profileJson = await jsonDecode(prefs.getString("profile")!);
    var newType = profileJson['type'] == 'Caretaker' ? 'Senior' : 'Caretaker';
    await Supabase.instance.client.from('Profiles').update({"type":newType}).eq("id", profileJson['id']).select().then((value){
      profileJson['type'] = newType;
      prefs.setString("profile", jsonEncode(profileJson));
      print(value);
    }).catchError((error){
      print(error);
    });
  }
}