import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  requestPermissions() async {
    await PermissionHandler().requestPermissions([
      PermissionGroup.storage,
      PermissionGroup.photos,
      PermissionGroup.microphone,
    ]);
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WebViewController _controller;
  String formattedDate;
  bool recording = false;
  Directory directory;
  bool inProgress = false;

  @override
  void initState() {
    super.initState();
    startScreenRecord(false);
  }

  Future<File> moveFile(File sourceFile, String newPath) async {
    try {
      // prefer using rename as it is probably faster
      return await sourceFile.rename(newPath);
    } on FileSystemException catch (e) {
      // if rename fails, copy the source file and then delete it
      final newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newFile;
    }
  }

  startScreenRecord(bool audio) async {
    var now = DateTime.now();
    var formatter = DateFormat('yyyy_MM_dd_HH_mm_ss');
    formattedDate = formatter.format(now);
    print('-------------');
    print(formattedDate);
    print('-------------');
    setState(() {
      recording = true;
    });

    if (audio) {
      await FlutterScreenRecording.startRecordScreenAndAudio(formattedDate);
    } else {
      await FlutterScreenRecording.startRecordScreen(formattedDate);
    }
  }

  Future<bool> stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    if (path != null) {
      setState(() {
        recording = false;
      });
      // create '/storage/emulated/0/DCIM/BackCamera/' directory
      directory = await Directory('/storage/emulated/0/DCIM/BackCamera')
          .create(recursive: true);
      final newPath = '${directory.path}/$formattedDate.mp4';
      final file = await moveFile(File(path), newPath);
      return true;
    } else {
      return false;
    }
  }

  String button_text = '녹화종료';
  Color _color = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("후방 카메라"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          Expanded(
            flex: 9,
            child: WebView(
              // initialUrl: 'http://10.10.10.1:8000/index.html',
              initialUrl: 'https://www.naver.com',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller = webViewController;
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () async {
                    final url = Uri.parse(
                      'http://www.nrc.go.kr/nrc/main.do',
                    );
                    if (await canLaunch(url.toString())) {
                      launch(url.toString());
                    } else {
                      print("Can't launch $url");
                    }
                  },
                  child: Image.asset(
                    'images/nrc.png',
                    width: 100,
                    height: 27,
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final url = Uri.parse(
                      'http://www.nrc.go.kr/at_rd/web/index.do',
                    );
                    if (await canLaunch(url.toString())) {
                      launch(url.toString());
                    } else {
                      print("Can't launch $url");
                    }
                  },
                  child: Image.asset(
                    'images/opcn.png',
                    width: 100,
                    height: 27,
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: _color,
                  ),
                  onPressed: () async {
                    if (button_text == '녹화시작') {
                      startScreenRecord(false);
                      setState(() {
                        button_text = '녹화종료';
                        _color = Colors.red;
                      });
                    } else {
                      bool stopped = await stopScreenRecord();
                      if (stopped) {
                        setState(() {
                          button_text = '녹화시작';
                          _color = Colors.green;
                        });
                      }
                    }
                  },
                  child: Text(button_text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
