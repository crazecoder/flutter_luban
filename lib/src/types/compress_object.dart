
import 'package:cross_file/cross_file.dart';

class CompressObject {
  final XFile imageXFile;

  ///compress to path
  ///web invalid
  final String? targetPath;

  ///If there is a cache, no compression will be performed
  ///web invalid
  final bool useCache;

  ///16/32/64/128/256/512/1024/2048+
  final int numberOfColors;

  ///convert image to RGB
  final bool toRgb;

  CompressObject({
    required this.imageXFile,
    this.targetPath,
    this.useCache = true,
    this.toRgb = true,
    this.numberOfColors = 128,
  });
}
