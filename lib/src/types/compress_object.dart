import 'dart:io';

class CompressObject {
  final File imageFile;
  ///compress to path
  final String targetPath;
  ///If there is a cache, no compression will be performed
  final bool useCache;
  ///Convert the image to jpg
  final bool toJpg;

  CompressObject({
    required this.imageFile,
    required this.targetPath,
    this.useCache = false,
    this.toJpg = false,
  });
}
