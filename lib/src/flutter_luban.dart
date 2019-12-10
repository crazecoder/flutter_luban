import 'dart:io';

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as im;
import 'dart:math';
import 'dart:ui';

class Luban {
  Luban._();

  static Future<_TrueCompressObject> _parseTrueCompressObject(
      CompressObject object) async {
    Uint8List uint8list = object.imageFile.readAsBytesSync();
    Codec codec = await instantiateImageCodec(uint8list);
    final FrameInfo frameInfo = await codec.getNextFrame();
    Image image = frameInfo.image;
    _TrueCompressObject _trueCompressObject = _TrueCompressObject(
      trueWidth: image.width,
      trueHeight: image.height,
      uint8list: uint8list,
      compressObject: object,
    );
    return _trueCompressObject;
  }

  static Future<String> compressImage(CompressObject object) async {
    _TrueCompressObject _trueCompressObject =
        await _parseTrueCompressObject(object);
    return compute(_lubanCompress, _trueCompressObject);
  }

  static Future<dynamic> compressImageQueue(CompressObject object) async {
    _TrueCompressObject _trueCompressObject =
        await _parseTrueCompressObject(object);
    final response = ReceivePort();
    await Isolate.spawn(_lubanCompressQueue, response.sendPort);
    final sendPort = await response.first;
    final answer = ReceivePort();
    sendPort.send([answer.sendPort, _trueCompressObject]);
    return answer.first;
  }

  static Future<List<String>> compressImageList(
      List<CompressObject> objects) async {
    List<_TrueCompressObject> _trueObjs = [];
    await objects.forEach((_obj) async {
      _TrueCompressObject _trueCompressObject =
          await _parseTrueCompressObject(_obj);
      _trueObjs.add(_trueCompressObject);
    });
    return compute(_lubanCompressList, _trueObjs);
  }

  static void _lubanCompressQueue(SendPort port) {
    final rPort = ReceivePort();
    port.send(rPort.sendPort);
    rPort.listen((message) {
      final send = message[0] as SendPort;
      final object = message[1] as _TrueCompressObject;
      send.send(_lubanCompress(object));
    });
  }

  static List<String> _lubanCompressList(List<_TrueCompressObject> objects) {
    var results = [];
    objects.forEach((_o) {
      results.add(_lubanCompress(_o));
    });
    return results;
  }

  static String _lubanCompress(_TrueCompressObject _trueCompressObject) {
    im.Image image = im.decodeImage(_trueCompressObject.uint8list);
    File imageFile = _trueCompressObject.compressObject.imageFile;
    String outPath = _trueCompressObject.compressObject.path;
    CompressMode mode = _trueCompressObject.compressObject.mode;
    int quality = _trueCompressObject.compressObject.quality;
    int step = _trueCompressObject.compressObject.step;

    var length = imageFile.lengthSync();
    print(imageFile.path);
    bool isJpg =
        imageFile.path.endsWith("jpg") || imageFile.path.endsWith("jpeg");
    bool isPng = false;

    if (!isJpg) isPng = imageFile.path.endsWith("png");

    bool isLandscape = false;
    double size;
    int fixelW = _trueCompressObject.trueWidth;
    int fixelH = _trueCompressObject.trueHeight;
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
      isLandscape = false;
    }
    var decodedImageFile;
    if (isJpg)
      decodedImageFile = new File(
          outPath + '/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
    else if (isPng)
      decodedImageFile = new File(
          outPath + '/img_${DateTime.now().millisecondsSinceEpoch}.png');
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
              .writeAsBytesSync(im.encodeJpg(image, quality: quality));
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
            .writeAsBytesSync(im.encodeJpg(image, quality: quality));
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
      decodedImageFile.writeAsBytesSync(im.encodeJpg(image, quality: quality));
      return decodedImageFile.path;
    }
    im.Image smallerImage;
    print("isLandscape=$isLandscape  thumbW=$thumbW   thumbH=$thumbH");
    if (isLandscape) {
      smallerImage = im.copyResize(image, width: thumbH.toInt());
    } else {
      smallerImage = im.copyResize(image, width: thumbW.toInt());
    }

    if (decodedImageFile.existsSync()) {
      decodedImageFile.deleteSync();
    }
    if (mode == CompressMode.LARGE2SMALL) {
      _large2SmallCompressImage(
        image: smallerImage,
        file: decodedImageFile,
        quality: quality,
        targetSize: size,
        step: step,
        isJpg: isJpg,
      );
    } else if (mode == CompressMode.SMALL2LARGE) {
      _small2LargeCompressImage(
        image: smallerImage,
        file: decodedImageFile,
        quality: step,
        targetSize: size,
        step: step,
        isJpg: isJpg,
      );
    } else {
      if (imageSize < 500) {
        _large2SmallCompressImage(
          image: smallerImage,
          file: decodedImageFile,
          quality: quality,
          targetSize: size,
          step: step,
          isJpg: isJpg,
        );
      } else {
        _small2LargeCompressImage(
          image: smallerImage,
          file: decodedImageFile,
          quality: step,
          targetSize: size,
          step: step,
          isJpg: isJpg,
        );
      }
    }
    return decodedImageFile.path;
  }

  static _large2SmallCompressImage({
    im.Image image,
    File file,
    quality,
    targetSize,
    step,
    bool isJpg: true,
  }) {
    if (isJpg) {
      var img = im.encodeJpg(image, quality: quality);
      var tempImageSize = Uint8List.fromList(img).lengthInBytes;
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
      file.writeAsBytesSync(img);
    } else {
      _compressPng(
        image: image,
        file: file,
        targetSize: targetSize,
      );
    }
  }

  static _small2LargeCompressImage({
    im.Image image,
    File file,
    quality,
    targetSize,
    step,
    bool isJpg: true,
  }) {
    if (isJpg) {
      var img = im.encodeJpg(image, quality: quality);
      var tempImageSize = Uint8List.fromList(img).lengthInBytes;
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
      file.writeAsBytesSync(img);
    } else {
      _compressPng(
        image: image,
        file: file,
        targetSize: targetSize,
      );
    }
  }

  static void _compressPng({
    im.Image image,
    File file,
    level: 9,
    targetSize,
  }) {
    var img = im.encodePng(image, level: level);
    var tempImageSize = Uint8List.fromList(img).lengthInBytes;
    if (tempImageSize / 1024 < targetSize) {
      _small2LargeCompressImage(
        image: image,
        file: file,
        targetSize: targetSize,
        isJpg: false,
      );
      return;
    }
    file.writeAsBytesSync(img);
  }
}

enum CompressMode {
  SMALL2LARGE,
  LARGE2SMALL,
  AUTO,
}

class CompressObject {
  final File imageFile;
  final String path;
  final CompressMode mode;
  final int quality;
  final int step;

  CompressObject({
    this.imageFile,
    this.path,
    this.mode: CompressMode.AUTO,
    this.quality: 80,
    this.step: 6,
  });
}

class _TrueCompressObject {
  final int trueWidth;
  final int trueHeight;
  final Uint8List uint8list;
  final CompressObject compressObject;

  _TrueCompressObject({
    this.trueWidth,
    this.trueHeight,
    this.uint8list,
    this.compressObject,
  });
}
