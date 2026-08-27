import 'dart:typed_data';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_luban/flutter_luban.dart';
import '../util.dart';

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
  final compressBeans = <CompressBean>[];

  // XFile? primaryFile;
  // XFile? compressedFile;
  var time_start = 0;
  var time = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("total time: $time ms"),
            Expanded(
              child: ListView.builder(
                itemBuilder: (_, index) => _item(index),
                itemCount: compressBeans.length,
                padding: EdgeInsets.only(top: 20),
              ),
            ),
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
              _pickImageList();
            },
            child: Icon(Icons.photo),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _item(int index) {
    final bean = compressBeans[index];
    final primaryFile = bean.primaryFile;
    final compressedFile = bean.compressedFile;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (primaryFile != null) _buildImage(primaryFile, "primary"),
        if (compressedFile != null) _buildImage(compressedFile, "compressed"),
      ],
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
    compressBeans.clear();
    XFile? imageXFile = await ImagePicker().pickImage(source: type);
    var bean = CompressBean(primaryFile: imageXFile);

    if (imageXFile == null) return;

    setState(() {
      compressBeans.add(bean);
      time_start = DateTime.now().millisecondsSinceEpoch;
    });
    // final tempDir = await getTemporaryDirectory();
    CompressObject compressObject = CompressObject(
      //image
      imageXFile: imageXFile,
      //compress to path
      // targetPath: tempDir.path,
      targetWidth: 1080,
      useCache: false,
      toRgb: true,
      numberOfColors: 128,
    );
    Luban.compressImage(compressObject).then((xfile) {
      setState(() {
        if (xfile == null) return;
        bean.compressedFile = xfile;
        time = DateTime.now().millisecondsSinceEpoch - time_start;
      });
    });
  }

  _pickImageList() async {
    compressBeans.clear();
    final imageXFileList = await ImagePicker().pickMultiImage();

    if (imageXFileList.isEmpty) return;
    time_start = DateTime.now().millisecondsSinceEpoch;
    // final tempDir = await getTemporaryDirectory();
    final objs = <CompressObject>[];
    imageXFileList.forEach((imageXFile) {
      compressBeans.add(CompressBean(primaryFile: imageXFile));
      objs.add(
        CompressObject(
          //image
          imageXFile: imageXFile,
          // bytes: bytes,
          //compress to path
          // targetPath: tempDir.path,
          useCache: false,
          toRgb: true,
          numberOfColors: 128,
        ),
      );
    });
    Luban.compressImageList(objs).then((xfiles) {
      time = DateTime.now().millisecondsSinceEpoch - time_start;
      print("compress success: ${xfiles.length}, time: $time ");
      for (int i = 0; i < xfiles.length; i++) {
        compressBeans[i].compressedFile = xfiles[i];
      }
      setState(() {});
    });
  }
}

class CompressBean {
  XFile? primaryFile;
  XFile? compressedFile;

  CompressBean({this.compressedFile, this.primaryFile});
}
