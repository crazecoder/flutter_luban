import 'dart:typed_data';
import 'package:flutter_luban/src/utils/image_parser.dart';
import 'package:image/image.dart' as img;

class Compressor {
  Compressor._();

  static Uint8List compress(
    img.Image image, {
    int? targetSizeKb,
    int? fixedQuality,
    int numberOfColors = 128,
    img.ImageFormat imageFormat = img.ImageFormat.jpg,
  }) {
    final rgbImage = imageFormat == img.ImageFormat.jpg
        ? ImageParser.convertToRgb(image)
        : image;

    if (fixedQuality != null) {
      return _encodeImage(
        rgbImage,
        quality: fixedQuality,
        imageFormat: imageFormat,
        numberOfColors: numberOfColors,
      );
    }

    if (targetSizeKb == null) {
      return _encodeImage(
        rgbImage,
        quality: 60,
        imageFormat: imageFormat,
        numberOfColors: numberOfColors,
      );
    }

    const low = 5;
    const high = 95;

    Uint8List? bestData;

    // test highest quality
    final testResult = _encodeImage(
      rgbImage,
      quality: 95,
      imageFormat: imageFormat,
      numberOfColors: numberOfColors,
    );

    final sizeKb = testResult.length / 1024.0;

    if (sizeKb <= targetSizeKb) {
      return testResult;
    }

    var currentLow = low;
    var currentHigh = high;

    while (currentLow <= currentHigh) {
      final mid = (currentLow + currentHigh) ~/ 2;
      if (imageFormat == img.ImageFormat.png) {
        int level = _getLevel(mid);
        if (level >= 9) {
          break;
        }
      }
      final compressed = _encodeImage(
        rgbImage,
        quality: mid,
        imageFormat: imageFormat,
        numberOfColors: numberOfColors,
      );

      final currentSizeKb = compressed.length / 1024.0;

      if (currentSizeKb <= targetSizeKb) {
        bestData = compressed;

        // try higher quality
        currentLow = mid + 1;
      } else {
        currentHigh = mid - 1;
      }
    }

    bestData ??= _encodeImage(
      rgbImage,
      quality: 5,
      imageFormat: imageFormat,
      numberOfColors: numberOfColors,
    );

    return bestData;
  }

  static Uint8List _encodeImage(
    img.Image image, {
    int quality = 100,
    int numberOfColors = 128,
    img.ImageFormat imageFormat = img.ImageFormat.jpg,
  }) {
    switch (imageFormat) {
      case img.ImageFormat.png:
        return img.encodePng(
          image.hasAlpha
              ? image
              : img.quantize(
                  image,
                  numberOfColors: numberOfColors,
                ),
          level: _getLevel(quality),
        );
      default:
        return img.encodeJpg(
          image,
          quality: quality,
        );
    }
  }

  static int _getLevel(int quality) {
    int level = ((100 - quality) / 100 * 9).ceil();
    return level;
  }
}
