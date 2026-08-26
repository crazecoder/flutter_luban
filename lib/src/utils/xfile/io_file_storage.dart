import 'dart:io';

import 'package:cross_file/cross_file.dart';

import 'interface.dart';

class IoXFileStorage implements XFileStorage {
  @override
  Future save(XFile file, String path) async {
    await file.saveTo(path);
  }

  @override
  Future delete(XFile file) async {
    await File(file.path).delete();
  }

  @override
  Future<bool> exists(XFile file) async {
    return File(file.path).exists();
  }

  @override
  String tempDir() {
   return Directory.systemTemp.path;
  }
}