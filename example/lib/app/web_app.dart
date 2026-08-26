import 'dart:typed_data';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:example/web_worker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../util.dart';

class WebApp extends StatelessWidget {
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
  Uint8List? primaryBytes;
  Uint8List? compressedBytes;
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
                  if (primaryBytes != null)
                    _buildImage(primaryBytes!, "primary"),
                  if (compressedBytes != null)
                    _buildImage(compressedBytes!, "compressed"),
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

  Widget _buildImage(Uint8List? bytes, String text) => Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(bytes == null ? '' : Utils.getRollupSize(bytes.length)),
        bytes != null
            ? GestureDetector(
              onTap: () {
                _showImagePop(bytes);
              },
              child: Image.memory(bytes),
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

  _showImagePop(Uint8List bytes) async {
    final imageProvider = Image.memory(bytes).image;
    showImageViewer(context, imageProvider);
  }

  _pickImage(ImageSource type) async {
    XFile? imageXFile = await ImagePicker().pickImage(source: type);

    if (imageXFile == null) return;
    setState(() {
      // primaryBytes = bytes;
      time_start = DateTime.now().millisecondsSinceEpoch;
    });
    final builder = await imageXFile.openRead().fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) {
        builder.add(chunk);
        return builder;
      },
    );

    final bytes = Uint8List.fromList(builder.takeBytes());
    setState(() {
      primaryBytes = bytes;
    });

    final compressBytes = await WebWorker.compress([imageXFile.path, bytes]);
    setState(() {
      if (compressBytes == null) return;

      compressedBytes = compressBytes;
      time = DateTime.now().millisecondsSinceEpoch - time_start;
    });
  }
}
