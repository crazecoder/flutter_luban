# flutter_luban
[![pub package](https://img.shields.io/pub/v/flutter_luban.svg)](https://pub.dartlang.org/packages/flutter_luban)

A image compress package like [Luban](https://github.com/Curzibn/Luban) for dart.

### Example
```dart
    CompressObject compressObject = CompressObject(
        imageFile:imageFile, //image
        path:tempDir.path, //compress to path
        mode: CompressMode.LARGE2SMALL,//default AUTO
      );
    Luban.compressImage(compressObject).then((_path) {
        setState(() {
          print(_path);
        });
    });
```
![](https://github.com/crazecoder/flutter_luban/blob/62bae66c5d067db82117038c6bb8bac2d54e14f9/screenshot/test.png?raw=true)
