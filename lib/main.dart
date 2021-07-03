import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picovoice/picovoice_manager.dart';
import 'package:picovoice/picovoice_error.dart';
import 'jarvis_widget.dart';
import 'mic_widget.dart';
import 'package:volume_control/volume_control.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Voice',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({Key? key}) : super(key: key);

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late PicovoiceManager _picovoiceManager;
  late double vol;

  int team1Score = 0;
  int team2Score = 0;
  bool micExpanded = false;
  bool jarvisListening = false;

  @override
  void initState() {
    super.initState();
    loadVolume();
  }

  void loadVolume() async {
    vol = await VolumeControl.volume;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text("Say \"Scoreboard\""),
        ),
        actions: [
          IconButton(
            icon: Icon(!jarvisListening ? Icons.mic : Icons.mic_off),
            onPressed: (){
              if(!jarvisListening) _initPicoVoice();
              else _turnOffCommand();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                getCard("Team 1", team1Score, 0),
                getCard("Team 2", team2Score, 1),
              ],
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: MicWidget(expanded: micExpanded),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: JarvisWidget(show: jarvisListening),
            ),
          ),
        ],
      ),
    );
  }

  Widget getCard(String text, int score, int index) {
    return Flexible(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Card(
            color: Colors.lightBlue,
            child: Column(
              children: [
                Text(
                  text,
                  style: TextStyle(fontSize: 30),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      score.toString(),
                      style:
                          TextStyle(fontSize: 60, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Row(
                  // mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getButton(
                        Icons.add,
                        () {
                          _addPoints(index, 1);
                        }),
                    getButton(
                        Icons.remove,
                        () {
                          _subtractPoints(index, 1);
                        })
                  ],
                )
              ],
            )),
      ),
    );
  }
  
  void _addPoints(int index, int points){
    setState(() =>
    index == 0 ? team1Score += points : team2Score += points);
  }
  
  void _subtractPoints(int index, int points){
    setState(() =>
    index == 0 ? team1Score -= points : team2Score -= points);
  }

  Widget getButton(IconData icon, Function onPressed) {
    return Flexible(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.black),
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
          child: Container(
            child: Icon(icon),
            width: double.infinity,
          ),
          onPressed: () => onPressed(),
        ),
      ),
    );
  }

  //**PICOVOICE STUFF**

  void _initPicoVoice() async{
    String platform = Platform.isAndroid ? "android" : "ios";
    String keywordAsset = "assets/$platform/jarvis_$platform.ppn";
    String keywordPath = await _extractAsset(keywordAsset);
    String contextAsset = "assets/$platform/scoreboard_$platform.rhn";
    String contextPath = await _extractAsset(contextAsset);

    try{
      _picovoiceManager = await PicovoiceManager.create(
        keywordPath,
        _wakeWordCallback,
        contextPath,
        _inferenceCallback,
      );

      _picovoiceManager.start();
      setState(() {
        jarvisListening = true;
      });
    } on PvError catch(ex){
      print(ex);
    }
  }

  void _wakeWordCallback() async {
    print("Wake word detected!");
    setState(() {
      micExpanded = true;
    });
    vol = await VolumeControl.volume;
    if(vol > .1) VolumeControl.setVolume(0.1);
  }

  void _inferenceCallback(Map<String, dynamic> inference){
    print(inference);
    if(inference['isUnderstood']){
      Map<String, String>slots = inference['slots'];
      String intentName = inference['intent'];
      if(intentName == 'addPoints'){
        _changeScoreCommand(true, slots);
      } else if(intentName == 'subtractPoints'){
        _changeScoreCommand(false, slots);
      } else if(intentName == 'chooseTeam'){
        _chooseTeamCommand();
      } else if(intentName == 'turnOff'){
        _turnOffCommand();
      }
    } else {
      _rejectCommand();
    }

    setState(() {
      micExpanded = false;
    });
    VolumeControl.setVolume(vol);
  }

  Future<String> _extractAsset(String path) async {
    String resourceDIR = (await getApplicationDocumentsDirectory()).path;
    String outputPath = '$resourceDIR/$path';
    File outputFile = new File(outputPath);

    ByteData data = await rootBundle.load(path);
    final buffer = data.buffer;

    await outputFile.create(recursive: true);
    await outputFile.writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    return outputPath;
  }
  
  void _changeScoreCommand(bool add, Map<String, String> slots){
    int teamNum = int.parse(slots['teamNum']!);
    if(teamNum == 1 || teamNum == 2){
      if(add){
        _addPoints(teamNum - 1, int.parse(slots['pointAmt']!));
      } else {
        _subtractPoints(teamNum - 1, int.parse(slots['pointAmt']!));
      }
    }
  }

  void _chooseTeamCommand(){
    print("Random team Chosen");
  }

  void _turnOffCommand(){
    // print("Unable to turn off");
    _picovoiceManager.stop();
    setState(() {
      jarvisListening = false;
    });
  }

  void _rejectCommand(){
    print("Jarvis couldn't understand what was said");
  }

}
