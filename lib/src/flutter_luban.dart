import 'dart:async';
import 'dart:isolate';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_luban/src/types/compress_object.dart';
import 'package:flutter_luban/src/utils/calculator.dart';
import 'package:flutter_luban/src/utils/compressor.dart';
import 'package:flutter_luban/src/utils/image_parser.dart';
import 'package:flutter_luban/src/utils/xfile/interface.dart';
import 'package:flutter_luban/src/utils/xfile/io_file_storage.dart';
import 'package:flutter_luban/src/utils/xfile/web_file_storage.dart';
import 'package:image/image.dart';

class Luban {
  static final CompressionCalculator _calculator = CompressionCalculator();
  static final XFileStorage _xFileStorage =
      kIsWeb ? WebFileStorage() : IoXFileStorage();

  Luban._();

  static Future<XFile?> compressImage(CompressObject object) async {
    return compute(_lubanCompress, object);
  }

  static Future<dynamic> compressImageQueue(CompressObject object) async {
    final response = ReceivePort();
    await Isolate.spawn(_lubanCompressQueue, response.sendPort);
    final sendPort = await response.first;
    final answer = ReceivePort();
    sendPort.send([answer.sendPort, object]);
    return answer.first;
  }

  static Future<List<XFile?>> compressImageList(
      List<CompressObject> objects) async {
    return compute(_lubanCompressList, objects);
  }

  static void _lubanCompressQueue(SendPort port) {
    final rPort = ReceivePort();
    port.send(rPort.sendPort);
    rPort.listen((message) {
      final send = message[0] as SendPort;
      final object = message[1] as CompressObject;
      send.send(_lubanCompress(object));
    });
  }

  static Future<List<XFile?>> _lubanCompressList(
      List<CompressObject> objects) async {
    var results = <XFile?>[];
    await Future.forEach(objects, (obj) async {
      results.add(await _lubanCompress(obj));
    });
    return results;
  }

  static Future<XFile?> _lubanCompress(CompressObject object) async {
    final originalFileName = object.imageXFile.path.split("/").last;
    String targetPath = object.targetPath ?? _xFileStorage.tempDir();
    final imageFormat =
        ImageParser.parseFormat(object.toRgb, object.imageXFile.path);
    XFile? decodedImageFile;
    String path =
        '$targetPath/luban_$originalFileName.${ImageParser.getSuffix(imageFormat)}';
    decodedImageFile = XFile(path);

    if (await _xFileStorage.exists(decodedImageFile)) {
      if (object.useCache) {
        return decodedImageFile;
      }
      _xFileStorage.delete(decodedImageFile);
    }
    final bytes = await _lubanCompressToBytes(object.imageXFile,
        targetWidth: object.targetWidth,
        toRgb: object.toRgb,
        numberOfColors: object.numberOfColors);
    if (bytes == null) return null;
    decodedImageFile = XFile.fromData(bytes);
    if (!kIsWeb) await decodedImageFile.saveTo(path);
    return decodedImageFile;
  }

  static Future<Uint8List?> _lubanCompressToBytes(XFile imageXFile,
      {int? targetWidth, bool toRgb = false, int numberOfColors = 128}) async {
    final bool exists = await _xFileStorage.exists(imageXFile);
    if (!exists) {
      return null;
    }
    final imageBytes = await imageXFile.readAsBytes();
    Image? image = decodeImage(imageBytes);
    if (image == null) {
      throw Exception("flutter_luban don't support this image type");
    }
    final format = ImageParser.parseFormat(toRgb, imageXFile.path);
    if (format == ImageFormat.jpg) {
      image = ImageParser.convertToRgb(image);
    }
    final target = _calculator.calculateTarget(image.width, image.height,
        targetWidth: targetWidth);
    if (target.width > 0 && target.width < image.width) {
      image = copyResize(
        image,
        width: target.width,
        height: target.height,
      );
    }
    final bytes = Compressor.compress(
      image,
      fixedQuality: !target.isLongImage ? 60 : null,
      targetSizeKb: target.targetSizeKb,
      imageFormat: format,
      numberOfColors: numberOfColors,
    );
    return bytes;
  }
}
