import 'dart:typed_data';
import 'package:image/image.dart' as img;

class Compressor {
  Compressor._();

  static Uint8List compress(
    img.Image image, {
    int? targetSizeKb,
    int? fixedQuality,
    img.ImageFormat imageFormat = img.ImageFormat.jpg,
  }) {
    final rgbImage =
        imageFormat != img.ImageFormat.png ? _convertToRgb(image) : image;

    if (fixedQuality != null) {
      return Uint8List.fromList(
        _encodeImage(
          rgbImage,
          quality: fixedQuality,
          imageFormat: imageFormat,
        ),
      );
    }

    if (targetSizeKb == null) {
      return Uint8List.fromList(
        _encodeImage(
          rgbImage,
          quality: 60,
          imageFormat: imageFormat,
        ),
      );
    }

    const low = 5;
    const high = 95;

    Uint8List? bestData;

    // test highest quality
    final testResult = Uint8List.fromList(
      _encodeImage(
        rgbImage,
        quality: 95,
        imageFormat: imageFormat,
      ),
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
      final compressed = Uint8List.fromList(
        _encodeImage(
          rgbImage,
          quality: mid,
          imageFormat: imageFormat,
        ),
      );

      final currentSizeKb = compressed.length / 1024.0;

      if (currentSizeKb <= targetSizeKb) {
        bestData = compressed;

        // 可以尝试更高质量
        currentLow = mid + 1;
      } else {
        currentHigh = mid - 1;
      }
    }

    bestData ??= Uint8List.fromList(
      _encodeImage(
        rgbImage,
        quality: 5,
        imageFormat: imageFormat,
      ),
    );

    return bestData;
  }

  static Uint8List _encodeImage(
    img.Image image, {
    int quality = 100,
    img.ImageFormat imageFormat = img.ImageFormat.jpg,
  }) {
    switch (imageFormat) {
      case img.ImageFormat.png:
        return img.encodePng(
          img.quantize(
            image,
            numberOfColors: 128,
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

  /// convert image to RGB
  static img.Image _convertToRgb(img.Image source) {
    final result = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 3,
    );

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        result.setPixelRgb(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
      }
    }

    return result;
  }

  static int _getLevel(int quality) {
    int level = ((100 - quality) / 100 * 9).ceil();
    return level;
  }
}
