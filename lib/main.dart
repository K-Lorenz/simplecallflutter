import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplecallflutter/utils/supabase_service.dart';
import 'package:simplecallflutter/utils/user.dart';
import 'package:simplecallflutter/utils/webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

var _profile;
var prefs;
String? _myName;

void main() async {
  await dotenv.load();
  await SupabaseService.initSupabase();
  prefs = await SharedPreferences.getInstance();
  if(Supabase.instance.client.auth.currentUser == null){
    await UserManager.login();
  }  if(prefs.get("profile")==null){
    await Supabase.instance.client.from('Profiles').insert([{'id': Supabase.instance.client.auth.currentUser!.id}]).select().then((value) async{
      await prefs.setString("profile", jsonEncode(value[0]));
    }).catchError((error){
      print(error);
    });
  }
  _profile = jsonDecode(await prefs.getString("profile"));
  Supabase.instance.client
      .channel("ReceivingCalls")
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'Signaling',
        //filter missing for ID
        callback: (payload) async{
          if(payload.newRecord['signal_type']=="CallRequest"){
            print("test");
            await WebRTCUtil().initWebRTC(payload.newRecord['caller_id'],payload.newRecord['data']);
          }
        }
      )
      .subscribe();
    
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
      home: const MyHomePage(title: 'Direkter Anruf'),
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

  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
    UserManager.updateUser('Papa',image!);
  }


  /*void _incrementCounter() {
    UserManager.createConnection("AEMCZR");
  }*/
  void loadProfile()async{
    await Supabase.instance.client.from('Profiles').select('*').eq('id', Supabase.instance.client.auth.currentUser!.id).then((value) async{
      await prefs.setString("profile", jsonEncode(value[0]));
      setState((){
        _profile = value[0];
      });
      print(value[0]);
    });
  }


  void checkConnections() async {
    print(await UserManager.getConnectionProfiles());
    await WebRTCUtil().initWebRTC("a8cd4ed8-303e-4f4c-a4f1-f549f396012f");
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
            _image == null
                ? Text('No image selected.')
                   : Image.file(File(_image!.path)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),    
            Text(_profile== null ? "not loaded" : _profile['id'], style: Theme.of(context).textTheme.headlineMedium,),
            Text(_profile== null ? "not loaded" : _profile['type'], style: Theme.of(context).textTheme.headlineMedium,),
            Text(_profile['full_name']== null ? "not loaded" : _profile['full_name'], style: Theme.of(context).textTheme.headlineMedium,),
          
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: checkConnections,
                  child: const Text("Check Connection Profiles"),
                ),
                ElevatedButton(
                  onPressed: loadProfile,
                  child: const Text("Load Profiles"),
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
        onPressed: () { Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InputPage()),);
               },
        tooltip: 'Einstellungen',
        child: const Icon(Icons.settings),
      ),
    );
  }
  /*
  void _navigateToNextScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => _NewScreen()));
  }
  */
}

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}


class _InputPageState extends State<InputPage> {
  final TextEditingController _nameController = TextEditingController();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = image;
    });
  }

  void _submitData() {
    if (_nameController.text.isNotEmpty && _image != null) {
      Navigator.pop(context, {
        'name': _nameController.text,
        'image': _image,
      });
      UserManager.updateUser(_nameController.text, _image!);
    } else {
      // Zeige eine Fehlermeldung, wenn der Name oder das Bild fehlt
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Fehler'),
            content: Text('Bitte geben Sie einen Namen ein und wählen Sie ein Bild aus.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eingabeseite'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
            SizedBox(height: 20),
            _image == null
                ? Text('Kein Bild ausgewählt.')
                : Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    child: Image.file(File(_image!.path),
                    fit: BoxFit.cover
                    ),
                ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Bild auswählen'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitData,
              child: Text('Bestätigen'),
            ),
          ],
        ),
      ),
    );
  }

}

/*
class _NewScreen extends StatelessWidget {
//class _NewScreen extends StatefulWidget {

String? _userName;

  Future<void> _askUserName() async {
    TextEditingController nameController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nutzername eingeben'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _userName = nameController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Bestätigen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutzername Abfrage Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userName == null
                ? const Text('Kein Name eingegeben.')
                : Text('Hallo, $_userName!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _askUserName,
              child: const Text('Name eingeben'),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*

//  @override
 // Future<void> _askUserName() async {
  //  TextEditingController nameController =  TextEditingController();
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Einstellungen')),
        body: const Center(
          child: const TextField(
            decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Vorname',
                    ), 
            style: TextStyle(fontSize: 24.0),
    //        controller:  nameController,
         ),
    //     _myName = nameController.text;
        ),
      );
   // }
  }
}
*/