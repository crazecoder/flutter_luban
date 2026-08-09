import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_luban/src/utils/calculator.dart';
import 'package:flutter_luban/src/utils/compressor.dart';
import 'package:flutter_luban/src/utils/image_parser.dart';
import 'package:image/image.dart';

import 'types/compress_object.dart';

class Luban {
  static final CompressionCalculator _calculator = CompressionCalculator();

  Luban._();

  static Future<String?> compressImage(CompressObject object) async {
    if (kIsWeb) {
      throw "Because the web does not support isolate, it does not support web image compression for the time being";
    }
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

  static Future<List<String?>> compressImageList(
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

  static List<String?> _lubanCompressList(List<CompressObject> objects) {
    var results = [];
    objects.forEach((_o) {
      results.add(_lubanCompress(_o));
    });
    return results as List<String?>;
  }

  static Future<String?> _lubanCompress(CompressObject object) async {
    Image? image = decodeImage(object.imageFile.readAsBytesSync());
    if (image == null) {
      throw Exception("flutter_luban don't support this image type");
    }
    ImageFormat format = ImageFormat.jpg;
    if (object.toJpg) {
      image = ImageParser.convertToJpg(image) ?? image;
    } else {
      format = ImageParser.parseFormat(object.imageFile.path);
    }
    final originalFileName = object.imageFile.path.split("/").last;
    File? decodedImageFile;
    decodedImageFile = File(
        '${object.targetPath}/luban_$originalFileName.${ImageParser.getSuffix(format)}');
    if (decodedImageFile.existsSync()) {
      if (object.useCache) {
        return decodedImageFile.path;
      }
      decodedImageFile.deleteSync();
    }
    final target = _calculator.calculateTarget(image.width, image.height);
    if (target.width > 0 && target.width < image.width) {
      image = copyResize(
        image,
        width: target.width,
        height: target.height,
      );
    }
    final data = Compressor.compress(
      image,
      targetSizeKb: target.targetSizeKb,
      imageFormat: format,
    );
    decodedImageFile.writeAsBytesSync(data);
    return decodedImageFile.path;
  }
}
