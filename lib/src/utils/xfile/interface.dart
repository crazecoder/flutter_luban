import 'package:cross_file/cross_file.dart';

abstract interface class XFileStorage {
  String tempDir();

  Future save(XFile file, String path);

  Future delete(XFile file);

  Future<bool> exists(XFile file);
}
