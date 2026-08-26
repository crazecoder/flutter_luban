import 'package:image/image.dart';

class ImageParser {
  static const _jpgSuffix = ["jpg", "jpeg", "JPG", "JPEG"];
  static const _pngSuffix = ["png", "PNG"];
  static const _webpSuffix = ["webp", "WEBP"];

  ImageParser._();

  /// convert image to RGB
  static Image convertToRgb(Image source, {bool isOld = false}) {
    if (isOld) {
      return _convertToRgbOld(source);
    }
    return source.convert(numChannels: 3);
  }

  static Image _convertToRgbOld(Image source) {
    final result = Image(
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

  static String getSuffix(ImageFormat imageFormat) {
    switch (imageFormat) {
      case ImageFormat.png:
        return "png";
      case ImageFormat.webp:
        return "webp";
      default:
        return "jpg";
    }
  }

  static ImageFormat parseFormat(bool toRgb,String path) {
    if(!toRgb){
      if (_parseType(path, _jpgSuffix)) {
        return ImageFormat.jpg;
      } else if (_parseType(path, _pngSuffix)) {
        return ImageFormat.png;
      } else if (_parseType(path, _webpSuffix)) {
        return ImageFormat.webp;
      }
    }
    return ImageFormat.jpg;
  }

  static bool _parseType(String path, List<String> suffix) {
    bool result = false;
    for (int i = 0; i < suffix.length; i++) {
      if (path.endsWith(suffix[i])) {
        result = true;
        break;
      }
    }
    return result;
  }
}
