import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'util.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? primaryFile;
  File? compressedFile;
  var time_start = 0;
  var time = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("$time"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (primaryFile != null) _buildImage(primaryFile!, "primary"),
                  if (compressedFile != null)
                    _buildImage(compressedFile!, "compressed"),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              _pickImage(ImageSource.camera);
            },
            child: Icon(Icons.camera),
          ),
          FloatingActionButton(
            onPressed: () {
              _pickImage(ImageSource.gallery);
            },
            child: Icon(Icons.photo),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildImage(File imageFile, String text) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "${imageFile?.lengthSync() == null ? '' : Utils.getRollupSize(imageFile!.lengthSync())}",
        ),
        imageFile != null
            ? GestureDetector(
              onTap: () {
                _showImagePop(imageFile);
              },
              child: Image.file(imageFile),
            )
            : Text(text),
      ],
    ),
  );

  _showImagePop(File file) async {
    final imageProvider = Image.file(file).image;
    showImageViewer(context, imageProvider);
  }

  _pickImage(ImageSource type) async {
    XFile? imageXFile = await ImagePicker().pickImage(source: type);

    if (imageXFile == null) return;

    final imageFile = File(imageXFile.path);
    setState(() {
      primaryFile = imageFile;
      time_start = DateTime.now().millisecondsSinceEpoch;
    });
    final tempDir = await getTemporaryDirectory();

    CompressObject compressObject = CompressObject(
      imageFile: imageFile, //image
      targetPath: tempDir.path, //compress to path
      useCache: false,
      toJpg: true,
    );
    Luban.compressImage(compressObject).then((_path) {
      setState(() {
        if (_path == null) return;

        compressedFile = File(_path);
        time = DateTime.now().millisecondsSinceEpoch - time_start;
      });
    });
  }
}
