//import 'dart:developer';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late html.VideoElement _preview;
  late html.MediaRecorder _recorder;
  late html.VideoElement _result;
  late html.ImageElement _image;

  @override
  void initState() {
    super.initState();
    _preview = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..width = html.window.innerWidth!
      ..height = html.window.innerHeight!;

    _result = html.VideoElement()
      ..autoplay = false
      ..muted = false
      ..width = html.window.innerWidth!
      ..height = html.window.innerHeight!
      ..controls = true;

    _image = html.ImageElement();

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('preview', (int _) => _preview);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('result', (int _) => _result);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('image', (int _) => _image);
  }

  Future<html.MediaStream?> _openCamera() async {
    final html.MediaStream? stream =
        await html.window.navigator.mediaDevices?.getUserMedia({
      'video': {
        'frameRate': {'ideal': 30, 'max': 30}
      },
      'audio': true
    });
    _preview.srcObject = stream;
    return stream;
  }

  void startRecording(html.MediaStream stream) {
    _recorder = html.MediaRecorder(stream);
    // This will trigger the 'dataavailable' event every 1000ms
    _recorder.start(1000);

    html.Blob blob = html.Blob([]);

    _recorder.addEventListener('dataavailable', (event) {
      blob = js.JsObject.fromBrowserObject(event)['data'];
      // Method 1: This blob has 30 frames of data, possibly use this data retrieve the first frame?
      // IM - 30 frames of data (1 second of video at 30fps)
      // Method 2: Alternatively, it is easier to just take a photo from the stream
      // This can be optimized
      stream.getVideoTracks().forEach((track) {
        if (track.readyState == 'live') {
          html.ImageCapture imageCapture = html.ImageCapture(track);
          imageCapture.takePhoto().then((blob) {
            final url = html.Url.createObjectUrl(blob);
            final img = html.ImageElement(src: url);
            _image.src = img.src;
          });
        }
      });
    }, true);

    _recorder.addEventListener('stop', (event) {
      final url = html.Url.createObjectUrl(blob);
      _result.src = url;

      final anchor = html.AnchorElement()
        ..href = _result.src
        ..style.display = 'none'
        ..download = 'recording.webm';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(_result.src);

      stream.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    });
  }

  void stopRecording() {
    _recorder.stop();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web Recording',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Web Recording Demo'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Recording Preview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'preview',
                ),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        final html.MediaStream? stream = await _openCamera();
                        startRecording(stream!);
                      },
                      child: Text('Start Recording'),
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: () => stopRecording(),
                      child: Text('Stop & save video'),
                    ),
                  ],
                ),
              ),
              Text(
                'Recording Result',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'result',
                ),
              ),
              Text(
                'Last Image',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10.0),
                width: 300,
                height: 200,
                color: Colors.blue,
                child: HtmlElementView(
                  key: UniqueKey(),
                  viewType: 'image',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
