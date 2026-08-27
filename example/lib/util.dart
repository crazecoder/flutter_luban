

class Utils{

  static const RollupSize_Units = ["GB", "MB", "KB", "B"];

  static String getRollupSize(int size) {
    int idx = 3;
    int r1 = 0;
    String result = "";
    while (idx >= 0) {
      int s1 = size % 1024;
      size = size >> 10;
      if (size == 0 || idx == 0) {
        r1 = (r1 * 100) ~/ 1024;
        if (r1 > 0) {
          if (r1 >= 10) {
            result = "$s1.$r1${RollupSize_Units[idx]}";
          } else {
            result = "$s1.0$r1${RollupSize_Units[idx]}";
          }
        } else {
          result = s1.toString() + RollupSize_Units[idx];
        }
        break;
      }
      r1 = s1;
      idx--;
    }
    return result;
  }
}