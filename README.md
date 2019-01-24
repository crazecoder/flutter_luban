# flutter_luban

A image compress package like [Luban](https://github.com/Curzibn/Luban) for dart.

### Example
```dart
    CompressObject compressObject = CompressObject(
         imageFile,//image
         tempDir.path,//compress to path
       );
       Luban.compressImage(compressObject).then((_path) {
         setState(() {
           print(_path);
         });
       });
```
![](https://github.com/crazecoder/flutter_luban/blob/62bae66c5d067db82117038c6bb8bac2d54e14f9/screenshot/test.png?raw=true)
