import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' as Foundation;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class Luban {
  Luban._();

  static Future<List<int>?> compressImage(CompressObject object) async {
    return compute(_lubanCompress, object);
  }

  static Future<File?> compressAndSaveImage(
      CompressObject object, String path) async {
    if (!Foundation.kIsWeb) {
      List<int>? bytes = await compute(_lubanCompress, object);
      if (bytes == null) {
        return null;
      }
      File file = File(path);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsBytesSync(bytes, flush: true);
      return file;
    } else {
      throw ('This function is not supported on the web');
    }
  }

  static Future<dynamic> compressImageQueue(CompressObject object) async {
    final response = ReceivePort();
    await Isolate.spawn(_lubanCompressQueue, response.sendPort);
    final sendPort = await response.first;
    final answer = ReceivePort();
    sendPort.send([answer.sendPort, object]);
    return answer.first;
  }

  static Future<List<List<int>?>> compressImageList(
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

  static List<List<int>?> _lubanCompressList(List<CompressObject> objects) {
    List<List<int>?> results = [];
    objects.forEach((_o) {
      results.add(_lubanCompress(_o));
    });
    return results;
  }

  static List<int>? _lubanCompress(CompressObject object) {
    Image image = decodeImage(object.bytes)!;
    var length = object.bytes.lengthInBytes;
    bool isLandscape = false;

    bool isJpg =
        object.imageType == ImageType.JPEG || object.imageType == ImageType.JPG;

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
    List<int> bytes;
    var imageSize = length / 1024;
    if (scale <= 1 && scale > 0.5625) {
      if (fixelH < 1664) {
        if (imageSize < 150) {
          bytes = (encodeJpg(image, quality: object.quality));
          return bytes;
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
        bytes = encodeJpg(image, quality: object.quality);
        return bytes;
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
      bytes = encodeJpg(image, quality: object.quality);
      return bytes;
    }
    Image smallerImage;
    if (isLandscape) {
      smallerImage = copyResize(image,
          width: thumbH.toInt(),
          height: object.autoRatio ? null : thumbW.toInt());
    } else {
      smallerImage = copyResize(image,
          width: thumbW.toInt(),
          height: object.autoRatio ? null : thumbH.toInt());
    }

    if (object.mode == CompressMode.LARGE2SMALL) {
      bytes = _large2SmallCompressImage(
        image: smallerImage,
        quality: object.quality,
        targetSize: size,
        step: object.step,
        isJpg: isJpg,
      );
    } else if (object.mode == CompressMode.SMALL2LARGE) {
      bytes = _small2LargeCompressImage(
        image: smallerImage,
        quality: object.step,
        targetSize: size,
        step: object.step,
        isJpg: isJpg,
      );
    } else {
      if (imageSize < 500) {
        bytes = _large2SmallCompressImage(
          image: smallerImage,
          quality: object.quality,
          targetSize: size,
          step: object.step,
          isJpg: isJpg,
        );
      } else {
        bytes = _small2LargeCompressImage(
          image: smallerImage,
          quality: object.step,
          targetSize: size,
          step: object.step,
          isJpg: isJpg,
        );
      }
    }
    return bytes;
  }

  static List<int> _large2SmallCompressImage({
    Image? image,
    quality,
    targetSize,
    step,
    bool isJpg: true,
  }) {
    if (isJpg) {
      var im = encodeJpg(image!, quality: quality);
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 > targetSize && quality > step) {
        quality -= step;
        return _large2SmallCompressImage(
          image: image,
          quality: quality,
          targetSize: targetSize,
          step: step,
        );
      }
      return im;
    } else {
      return _compressPng(
        image: image!,
        targetSize: targetSize,
        large2Small: true,
      );
    }
  }

  static List<int> _small2LargeCompressImage({
    Image? image,
    quality,
    targetSize,
    step,
    bool isJpg: true,
  }) {
    if (isJpg) {
      var im = encodeJpg(image!, quality: quality);
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 < targetSize && quality <= 100) {
        quality += step;
        return _small2LargeCompressImage(
          image: image,
          quality: quality,
          targetSize: targetSize,
          step: step,
          isJpg: isJpg,
        );
      }
      return im;
    } else {
      return _compressPng(
        image: image!,
        targetSize: targetSize,
        large2Small: false,
      );
    }
  }

  ///level 1~9  level++ -> image--
  static List<int> _compressPng({
    required Image image,
    level,
    targetSize,
    required bool large2Small,
  }) {
    var _level;
    if (large2Small) {
      _level = level ?? 1;
    } else {
      _level = level ?? 9;
    }
    List<int> im = encodePng(image, level: _level);
    if (_level > 9 || _level < 1) {
    } else {
      var tempImageSize = Uint8List.fromList(im).lengthInBytes;
      if (tempImageSize / 1024 > targetSize) {
        return _compressPng(
          image: image,
          targetSize: targetSize,
          level: large2Small ? _level + 1 : _level - 1,
          large2Small: large2Small,
        );
        //return;
      }
    }
    return im;
  }
}

enum CompressMode {
  SMALL2LARGE,
  LARGE2SMALL,
  AUTO,
}

enum ImageType { JPG, JPEG, PNG }

class CompressObject {
  final Uint8List bytes;
  final ImageType? imageType;
  final CompressMode mode;
  final int quality;
  final int step;

  ///If you are not sure whether the image detail property is correct, set true, otherwise the compressed ratio may be incorrect
  final bool autoRatio;

  CompressObject({
    required this.bytes,
    required this.imageType,
    this.mode: CompressMode.AUTO,
    this.quality: 80,
    this.step: 6,
    this.autoRatio = true,
  });
}
