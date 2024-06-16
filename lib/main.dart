import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplecallflutter/utils/supabase_service.dart';
import 'package:simplecallflutter/utils/user.dart';
import 'package:simplecallflutter/utils/webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

var prefs;
var _profile;
void main() async {
  await dotenv.load();
  await SupabaseService.initSupabase();
  prefs = await SharedPreferences.getInstance();
  if(Supabase.instance.client.auth.currentUser == null){
    await UserManager.login();
  }
  if(prefs.get("profile")==null){
    await Supabase.instance.client.from('Profiles').insert([{'id': Supabase.instance.client.auth.currentUser!.id}]).select().then((value) async{
      await prefs.setString("profile", jsonEncode(value[0]));
    }).catchError((error){
      print(error);
    });
  }
  _profile = jsonDecode(await prefs.getString("profile"));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  void _incrementCounter() {
    UserManager.createConnection("AEMCZR");
  }
  void checkConnections() async {
    print(await UserManager.getConnectionProfiles());
    await WebRTCUtil().initWebRTC("b9181d88-9f15-4c48-ab26-80ee41777316");
  }
  void swapType() async{
    await UserManager.swapType();
    setState(() {
      _profile = jsonDecode(prefs.getString("profile")!);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_profile== null ? "not loaded" : _profile['id'], style: Theme.of(context).textTheme.headlineMedium,),
            Text(_profile== null ? "not loaded" : _profile['type'], style: Theme.of(context).textTheme.headlineMedium,),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: checkConnections,
                  child: const Text("Check Connection Profiles"),
                ),
              ],
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: swapType,
                  child: const Text("Swap Type"),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
