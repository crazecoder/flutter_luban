import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:zoomable_image/zoomable_image.dart';
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
  File primaryFile;
  File compressedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildImage(primaryFile, "primary"),
            _buildImage(compressedFile, "compressed"),
          ],
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
          )
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildImage(File imageFile, String text) => Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
                "${imageFile?.lengthSync() == null ? '' : Utils.getRollupSize(imageFile?.lengthSync())}"),
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

  _showImagePop(file) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: ZoomableImage(FileImage(file)),
          );
        });
  }

  _pickImage(ImageSource type) async {
    File imageFile = await ImagePicker.pickImage(source: type);
    setState(() {
      primaryFile = imageFile;
    });
    if (imageFile == null) return;
    final tempDir = await getTemporaryDirectory();

    CompressObject compressObject = CompressObject(
      imageFile,//image
      tempDir.path,//compress to path
    );
    Luban.compressImage(compressObject).then((_path) {
      setState(() {
        compressedFile = File(_path);
      });
    });
  }
}
