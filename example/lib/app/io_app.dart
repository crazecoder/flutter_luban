import 'dart:typed_data';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_luban/flutter_luban.dart';
import '../util.dart';

class IoApp extends StatelessWidget {
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
  XFile? primaryFile;
  XFile? compressedFile;
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

  Widget _buildImage(XFile? imageFile, String text) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FutureBuilder<int?>(
          future: _getImageBytesLength(imageFile),
          builder: (_, snapshot) {
            return Text(
              snapshot.data == null ? '' : Utils.getRollupSize(snapshot.data!),
            );
          },
        ),
        imageFile != null
            ? GestureDetector(
              onTap: () {
                _showImagePop(imageFile);
              },
              child: FutureBuilder<Uint8List>(
                future: _getImageBytes(imageFile),
                builder: (_, snapshot) {
                  return snapshot.data?.isNotEmpty == true
                      ? Image.memory(snapshot.data!)
                      : SizedBox.shrink();
                },
              ),
            )
            : Text(text),
      ],
    ),
  );

  Future<int?> _getImageBytesLength(XFile? image) async {
    return await image?.length();
  }

  Future<Uint8List> _getImageBytes(XFile image) async {
    return await image.readAsBytes();
  }

  _showImagePop(XFile file) async {
    final bytes = await _getImageBytes(file);
    final imageProvider = Image.memory(bytes).image;
    showImageViewer(context, imageProvider);
  }

  _pickImage(ImageSource type) async {
    XFile? imageXFile = await ImagePicker().pickImage(source: type);

    if (imageXFile == null) return;

    setState(() {
      primaryFile = imageXFile;
      time_start = DateTime.now().millisecondsSinceEpoch;
    });
    final tempDir = await getTemporaryDirectory();
    CompressObject compressObject = CompressObject(
      //image
      imageXFile: imageXFile,
      //compress to path
      targetPath: tempDir.path,
      useCache: true,
      toRgb: true,
      numberOfColors: 128,
    );
    Luban.compressImage(compressObject).then((xfile) {
      setState(() {
        if (xfile == null) return;
        compressedFile = xfile;
        time = DateTime.now().millisecondsSinceEpoch - time_start;
      });
    });
  }

  _pickImageList() async {
    final imageXFileList = await ImagePicker().pickMultiImage();

    if (imageXFileList.isEmpty) return;
    time_start = DateTime.now().millisecondsSinceEpoch;
    final tempDir = await getTemporaryDirectory();
    final objs = <CompressObject>[];
    imageXFileList.forEach((imageXFile) {
      objs.add(
        CompressObject(
          //image
          imageXFile: imageXFile,
          // bytes: bytes,
          //compress to path
          targetPath: tempDir.path,
          useCache: false,
          toRgb: true,
          numberOfColors: 128,
        ),
      );
    });
    Luban.compressImageList(objs).then((paths) {
      time = DateTime.now().millisecondsSinceEpoch - time_start;
      print("compress success: ${paths.length}, time: $time ");
    });
  }
}
