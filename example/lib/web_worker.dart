import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:flutter_luban/flutter_luban.dart';

class WebWorker {
  @isolateManagerWorker
  static Future<Uint8List?> compress(dynamic args) async {
    final path = args[0] as String?;
    final bytes = args[1] as Uint8List?;
    // final stream = args[1] as Stream<Uint8List>;
    // final bytes = await stream.fold<BytesBuilder>(
    //   BytesBuilder(),
    //       (builder, chunk) {
    //     builder.add(chunk);
    //     return builder;
    //   },
    // ).then((builder) => builder.takeBytes());
    if (bytes?.isNotEmpty != true) return null;
    CompressObject compressObject = CompressObject(
      //image
      imageXFile: XFile.fromData(bytes!, path: path),
      //compress to path
      useCache: false,
      toRgb: true,
      numberOfColors: 128,
    );
    final xfile = await Luban.compressImage(compressObject);
    return xfile?.readAsBytes();
  }
}
