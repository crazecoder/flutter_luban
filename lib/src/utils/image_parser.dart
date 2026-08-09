import 'dart:typed_data';

import 'package:image/image.dart';

class ImageParser {
  static const _jpgSuffix = ["jpg", "jpeg", "JPG", "JPEG"];
  static const _pngSuffix = ["png", "PNG"];
  static const _webpSuffix = ["webp", "WEBP"];

  ImageParser._();

  static Image? convertToJpg(
    Image image, {
    int quality = 90,
  }) {
    final bytes = encodeJpg(
      image,
      quality: quality,
    );
    return decodeImage(bytes);
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

  static ImageFormat parseFormat(String path) {
    if (_parseType(path, _jpgSuffix)) {
      return ImageFormat.jpg;
    } else if (_parseType(path, _pngSuffix)) {
      return ImageFormat.png;
    } else if (_parseType(path, _webpSuffix)) {
      return ImageFormat.webp;
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
