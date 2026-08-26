import 'package:cross_file/cross_file.dart';
import 'package:flutter_luban/src/utils/xfile/interface.dart';

class WebFileStorage implements XFileStorage {
  @override
  Future delete(XFile file) async {}

  @override
  Future<bool> exists(XFile file) async {
    try {
      await file.length();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> save(XFile file, String path) async {}

  @override
  String tempDir() {
    return "";
  }
}
