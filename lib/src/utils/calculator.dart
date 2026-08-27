import 'dart:math';

class CompressionTarget {
  final int width;
  final int height;
  final int estimatedSizeKb;
  final bool isLongImage;
  final int? targetSizeKb;

  const CompressionTarget(
    this.width,
    this.height,
    this.estimatedSizeKb, {
    this.isLongImage = false,
    this.targetSizeKb,
  });

  @override
  String toString() {
    return 'CompressionTarget(width: $width, height: $height, '
        'estimatedSizeKb: $estimatedSizeKb, '
        'isLongImage: $isLongImage, '
        'targetSizeKb: $targetSizeKb)';
  }
}

class CompressionCalculator {
  final int baseShort = 1440;
  final int wallLong = 10800;
  final double wallRatio = 0.4;
  final int trapPixels = 40960000;
  final int capPixels = 10240000;

  CompressionTarget calculateTarget(int width, int height, {int? targetWidth}) {
    if (width <= 0 || height <= 0) {
      return const CompressionTarget(0, 0, 0);
    }

    final shortSide = min(width, height);
    final longSide = max(width, height);
    final ratio = shortSide.toDouble() / longSide;
    final pixelCount = width * height;

    var targetShort = targetWidth == null ? baseShort : targetWidth;
    var targetLong = (targetShort / ratio).toInt();

    if (longSide >= wallLong && ratio > wallRatio) {
      targetLong = baseShort;
      targetShort = (targetLong * ratio).toInt();
    }

    if (pixelCount > trapPixels) {
      final trapShort = (shortSide * 0.25).toInt();

      if (trapShort < targetShort) {
        targetShort = trapShort;
        targetLong = (targetShort / ratio).toInt();
      }
    }

    if (targetShort > shortSide) {
      targetShort = shortSide;
      targetLong = longSide;
    }

    var currentPixels = targetShort * targetLong;

    if (currentPixels > capPixels) {
      final scale = (sqrt(capPixels / currentPixels) * 1000).floor() / 1000.0;

      targetShort = (targetShort * scale).toInt();
      targetLong = (targetLong * scale).toInt();
    }

    targetShort = (targetShort ~/ 2) * 2;
    targetLong = (targetLong ~/ 2) * 2;

    targetShort = max(2, targetShort);
    targetLong = max(2, targetLong);

    final int finalW;
    final int finalH;

    if (width < height) {
      finalW = targetShort;
      finalH = targetLong;
    } else {
      finalW = targetLong;
      finalH = targetShort;
    }

    final finalPixels = finalW * finalH;

    final double factor;

    if (finalPixels < 500000) {
      factor = 0.0005;
    } else if (finalPixels < 1000000) {
      factor = 0.00015;
    } else if (finalPixels < 3000000) {
      factor = 0.00011;
    } else {
      factor = 0.000025;
    }

    var estimatedSize = (finalPixels * factor).toInt();

    estimatedSize = max(20, estimatedSize);

    if (ratio < 0.2 && estimatedSize < 400) {
      estimatedSize = max(estimatedSize, 250);
    }

    final isLongImage = ratio <= 0.5;

    final targetSizeKb = isLongImage ? estimatedSize : null;

    return CompressionTarget(
      finalW,
      finalH,
      estimatedSize,
      isLongImage: isLongImage,
      targetSizeKb: targetSizeKb,
    );
  }
}
