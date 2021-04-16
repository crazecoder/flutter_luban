import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class Luban {
  Luban._();

  static Future<String?> compressImage(CompressObject object) async {
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

  static bool _parseType(String path, List<String> suffix) {
    bool _result = false;
    for (int i = 0; i < suffix.length; i++) {
      if (path.endsWith(suffix[i])) {
        _result = true;
        break;
      }
    }
    return _result;
  }

  static String? _lubanCompress(CompressObject object) {
    Image image = decodeImage(object.imageFile!.readAsBytesSync())!;
    var length = object.imageFile!.lengthSync();
    print(object.imageFile!.path);
    bool isLandscape = false;
    const List<String> jpgSuffix = ["jpg", "jpeg", "JPG", "JPEG"];
    const List<String> pngSuffix = ["png", "PNG"];
    bool isJpg = _parseType(object.imageFile!.path, jpgSuffix);
    bool isPng = false;

    if (!isJpg) isPng = _parseType(object.imageFile!.path, pngSuffix);

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
          object.path! + '/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
    else if (isPng)
      decodedImageFile = new File(
          object.path! + '/img_${DateTime.now().millisecondsSinceEpoch}.png');
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
      smallerImage = copyResize(image,
          width: thumbH.toInt(),
          height: object.autoRatio ? null : thumbW.toInt());
    } else {
      smallerImage = copyResize(image,
          width: thumbW.toInt(),
          height: object.autoRatio ? null : thumbH.toInt());
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
    Image? image,
    File? file,
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
        _large2SmallCompressImage(
          image: image,
          file: file,
          quality: quality,
          targetSize: targetSize,
          step: step,
        );
        return;
      }
      file!.writeAsBytesSync(im);
    } else {
      _compressPng(
        image: image!,
        file: file,
        targetSize: targetSize,
        large2Small: true,
      );
    }
  }

  static _small2LargeCompressImage({
    Image? image,
    File? file,
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
      file!.writeAsBytesSync(im);
    } else {
      _compressPng(
        image: image!,
        file: file,
        targetSize: targetSize,
        large2Small: false,
      );
    }
  }

  ///level 1~9  level++ -> image--
  static void _compressPng({
    required Image image,
    File? file,
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
        _compressPng(
          image: image,
          file: file,
          targetSize: targetSize,
          level: large2Small ? _level + 1 : _level - 1,
          large2Small: large2Small,
        );
        return;
      }
    }

    file!.writeAsBytesSync(im);
  }
}

enum CompressMode {
  SMALL2LARGE,
  LARGE2SMALL,
  AUTO,
}

class CompressObject {
  final File? imageFile;
  final String? path;
  final CompressMode mode;
  final int quality;
  final int step;

  ///If you are not sure whether the image detail property is correct, set true, otherwise the compressed ratio may be incorrect
  final bool autoRatio;

  CompressObject({
    this.imageFile,
    this.path,
    this.mode: CompressMode.AUTO,
    this.quality: 80,
    this.step: 6,
    this.autoRatio = true,
  });
}
