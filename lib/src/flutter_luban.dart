import 'dart:io';

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'dart:math';

class Luban {
  Luban._();

  static Future<String> compressImage(CompressObject object) async {
    return compute(_lubanCompress, object);
  }

  static Future<String> compressImageQueue(CompressObject object) async {
    final response = ReceivePort();
    await Isolate.spawn(_lubanCompressQueue, response.sendPort);
    final sendPort = await response.first;
    final answer = ReceivePort();
    sendPort.send([answer.sendPort, object]);
    return answer.first;
  }

  static Future<List<String>> compressImageList(List<CompressObject> objects) async {
    return compute(_lubanCompressList, objects);
  }
  static void _lubanCompressQueue(SendPort port){
    final rPort = ReceivePort();
    port.send(rPort.sendPort);
    rPort.listen((message) {
      final send = message[0] as SendPort;
      final object = message[1] as CompressObject;
      send.send(_lubanCompress(object));
    });
  }
  static List<String> _lubanCompressList(List<CompressObject> objects){
    var results = [];
    objects.forEach((_o){
      results.add(_lubanCompress(_o));
    });
    return results;
  }

  static String _lubanCompress(CompressObject object) {
    Image image = decodeImage(object.imageFile.readAsBytesSync());
    var length = object.imageFile.lengthSync();
    print(object.imageFile.path);
    bool isLandscape = false;
    bool isJpg = object.imageFile.path.endsWith("jpg") ||
        object.imageFile.path.endsWith("jpeg");
    bool isPng = false;

    if (!isJpg) isPng = object.imageFile.path.endsWith("png");

    double size;
    int fixelW = image.width;
    int fixelH = image.height;
    double thumbW = (fixelW % 2 == 1 ? fixelW + 1 : fixelW).toDouble();
    double thumbH = (fixelH % 2 == 1 ? fixelH + 1 : fixelH).toDouble();
    double scale = 0;
    if (fixelW > fixelH) {
      scale = fixelH / fixelW;
      var tempFixelH = fixelW;
      var tempFixelW = fixelH;
      fixelH = tempFixelH;
      fixelW = tempFixelW;
      isLandscape = true;
    } else {
      scale = fixelW / fixelH;
    }
    var decodedImageFile;
    if (isJpg)
      decodedImageFile = new File(
          object.path + '/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
    else if (isPng)
      decodedImageFile = new File(
          object.path + '/img_${DateTime.now().millisecondsSinceEpoch}.png');
    else
      throw Exception("flutter_luban don't support this image type");

    if (decodedImageFile.existsSync()) {
      decodedImageFile.deleteSync();
    }
    var imageSize = length / 1024;
    if (scale <= 1 && scale > 0.5625) {
      if (fixelH < 1664) {
        if (imageSize < 150) {
          decodedImageFile
              .writeAsBytesSync(encodeJpg(image, quality: object.quality));
          return decodedImageFile.path;
        }
        size = (fixelW * fixelH) / pow(1664, 2) * 150;
        size = size < 60 ? 60 : size;
      } else if (fixelH >= 1664 && fixelH < 4990) {
        thumbW = fixelW / 2;
        thumbH = fixelH / 2;
        size = (thumbH * thumbW) / pow(2495, 2) * 300;
        size = size < 60 ? 60 : size;
      } else if (fixelH >= 4990 && fixelH < 10240) {
        thumbW = fixelW / 4;
        thumbH = fixelH / 4;
        size = (thumbW * thumbH) / pow(2560, 2) * 300;
        size = size < 100 ? 100 : size;
      } else {
        int multiple = fixelH / 1280 == 0 ? 1 : fixelH ~/ 1280;
        thumbW = fixelW / multiple;
        thumbH = fixelH / multiple;
        size = (thumbW * thumbH) / pow(2560, 2) * 300;
        size = size < 100 ? 100 : size;
      }
    } else if (scale <= 0.5625 && scale >= 0.5) {
      if (fixelH < 1280 && imageSize < 200) {
        decodedImageFile
            .writeAsBytesSync(encodeJpg(image, quality: object.quality));
        return decodedImageFile.path;
      }
      int multiple = fixelH / 1280 == 0 ? 1 : fixelH ~/ 1280;
      thumbW = fixelW / multiple;
      thumbH = fixelH / multiple;
      size = (thumbW * thumbH) / (1440.0 * 2560.0) * 200;
      size = size < 100 ? 100 : size;
    } else {
      int multiple = (fixelH / (1280.0 / scale)).ceil();
      thumbW = fixelW / multiple;
      thumbH = fixelH / multiple;
      size = ((thumbW * thumbH) / (1280.0 * (1280 / scale))) * 500;
      size = size < 100 ? 100 : size;
    }
    if (imageSize < size) {
      decodedImageFile
          .writeAsBytesSync(encodeJpg(image, quality: object.quality));
      return decodedImageFile.path;
    }
    Image smallerImage;
    if (isLandscape) {
      smallerImage = copyResize(image, width:thumbH.toInt(), height:thumbW.toInt());
    } else {
      smallerImage = copyResize(image, width:thumbW.toInt(), height:thumbH.toInt());
    }
    if (decodedImageFile.existsSync()) {
      decodedImageFile.deleteSync();
    }
    if (object.mode == CompressMode.LARGE2SMALL) {
      _large2SmallCompressImage(
        image: smallerImage,
        file: decodedImageFile,
        quality: object.quality,
        targetSize: size,
        step: object.step,
        isJpg: isJpg,
      );
    } else if (object.mode == CompressMode.SMALL2LARGE) {
      _small2LargeCompressImage(
        image: smallerImage,
        file: decodedImageFile,
        quality: object.step,
        targetSize: size,
        step: object.step,
        isJpg: isJpg,
      );
    } else {
      if (imageSize < 500) {
        _large2SmallCompressImage(
          image: smallerImage,
          file: decodedImageFile,
          quality: object.quality,
          targetSize: size,
          step: object.step,
          isJpg: isJpg,
        );
      } else {
        _small2LargeCompressImage(
          image: smallerImage,
          file: decodedImageFile,
          quality: object.step,
          targetSize: size,
          step: object.step,
          isJpg: isJpg,
        );
      }
    }
    return decodedImageFile.path;
  }

  static _large2SmallCompressImage({
    Image image,
    File file,
    quality,
    targetSize,
    step,
    bool isJpg: true,
  }) {
    if(isJpg){
      var im = encodeJpg(image, quality: quality);
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 > targetSize && quality > step) {
        quality -= step;
        _large2SmallCompressImage(
          image: image,
          file: file,
          quality: quality,
          targetSize: targetSize,
          step: step,
        );
        return;
      }
      file.writeAsBytesSync(im);
    }else{
      _compressPng(
        image: image,
        file: file,
        targetSize: targetSize,
      );
    }
  }

  static _small2LargeCompressImage({
    Image image,
    File file,
    quality,
    targetSize,
    step,
    bool isJpg: true,
  }) {
    if (isJpg){
      var im = encodeJpg(image, quality: quality);
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 < targetSize && quality <= 100) {
        quality += step;
        _small2LargeCompressImage(
          image: image,
          file: file,
          quality: quality,
          targetSize: targetSize,
          step: step,
          isJpg: isJpg,
        );
        return;
      }
      file.writeAsBytesSync(im);
    }else{
      _compressPng(
        image: image,
        file: file,
        targetSize: targetSize,
      );
    }
  }

  static void _compressPng({
    Image image,
    File file,
    level: 9,
    targetSize,
  }) {
    var im = encodePng(image, level: level);
    var tempImageSize = Uint8List.fromList(im).lengthInBytes;
    if (tempImageSize / 1024 < targetSize) {
      _small2LargeCompressImage(
        image: image,
        file: file,
        targetSize: targetSize,
        isJpg: false,
      );
      return;
    }
    file.writeAsBytesSync(im);
  }
}

enum CompressMode {
  SMALL2LARGE,
  LARGE2SMALL,
  AUTO,
}

class CompressObject {
  File imageFile;
  String path;
  CompressMode mode;
  int quality;
  int step;

  CompressObject(
      {this.imageFile,
      this.path,
      this.mode: CompressMode.AUTO,
      this.quality: 80,
      this.step: 6});
}
