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
![](https://raw.githubusercontent.com/crazecoder/flutter_luban/master/screenshot/test.png)