# flutter_luban
[![pub package](https://img.shields.io/pub/v/flutter_luban.svg)](https://pub.dartlang.org/packages/flutter_luban)

An image compress package like [Luban](https://github.com/Curzibn/Luban) for Dart, based on [image](https://github.com/brendan-duncan/image).This library has no system platform constraints.

If ```toRgb: true``` , it supports all readable image formats 

[Readable Format](https://github.com/brendan-duncan/image/blob/main/doc/formats.md)

### Example
```dart
   CompressObject compressObject = CompressObject(
         imageXFile: imageXFile, //image file
         path: tempDir.path, //compress to path, default Directory.systemTemp.path
         useCache: true, //If there is a cache, no compression will be performed
         toRgb: true, //Convert the image to jpg
         numberOfColors: 128, //the numberOfColors of image.quantize
       );
    Luban.compressImage(compressObject).then((xfile) {
        setState(() {
          print(xfile.path);
        });
    });
```
![](https://github.com/crazecoder/flutter_luban/blob/62bae66c5d067db82117038c6bb8bac2d54e14f9/screenshot/test.png?raw=true)
