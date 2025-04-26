import 'dart:io';

import 'compress_mode.dart';

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
    this.mode = CompressMode.AUTO,
    this.quality = 80,
    this.step = 6,
    this.autoRatio = true,
  });
}