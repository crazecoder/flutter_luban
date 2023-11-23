import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:photo_view/photo_view.dart';
import 'util.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List primaryFile;
  Uint8List compressedFile;
  var time_start = 0;
  var time = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("$time"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildImage(primaryFile, "primary"),
                _buildImage(compressedFile, "compressed"),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              _pickImage();
            },
            child: Icon(Icons.photo),
          )
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildImage(Uint8List imageFile, String text) => Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("${Utils.getRollupSize(imageFile?.length ?? 0)}"),
            imageFile != null
                ? GestureDetector(
                    onTap: () {
                      _showImagePop(imageFile);
                    },
                    child: Image.memory(imageFile),
                  )
                : Text(text),
          ],
        ),
      );

  _showImagePop(Uint8List file) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: PhotoView(imageProvider: MemoryImage(file)),
          );
        });
  }

  _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    setState(() {
      // primaryFile = imageFile;
      time_start = DateTime.now().millisecondsSinceEpoch;
    });
    if (result == null) return;
    final String imageExt = result.files.first.name.split(".").last;
    final Uint8List imageBytes = result.files.first.bytes ??
        File(result.files.first.path).readAsBytesSync();
    CompressObject compressObject = CompressObject(
      imageExt: imageExt,
      imageBytes: imageBytes,
      quality: 85,
      step: 9,
    );
    Luban.compressRowImage(compressObject).then((compressedBytes) {
      setState(() {
        primaryFile = imageBytes;
        compressedFile = compressedBytes;
        time = DateTime.now().millisecondsSinceEpoch - time_start;
      });
    });
  }
}
