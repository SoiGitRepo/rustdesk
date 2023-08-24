import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hbb/common.dart';

Future<ui.Image> decodeImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
  ui.PixelFormat format, {
  int? rowBytes,
  int? targetWidth,
  int? targetHeight,
  VoidCallback? onPixelsCopied,
  bool allowUpscaling = true,
}) async {
  if (targetWidth != null) {
    assert(allowUpscaling || targetWidth <= width);
  }
  if (targetHeight != null) {
    assert(allowUpscaling || targetHeight <= height);
  }

  Uint8List rotatedImageData = rotation != 0 ? rotateImageArbitrary(pixels,width,height,rotation) : pixels;

  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(rotatedImageData);
  onPixelsCopied?.call();
  final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: height,
    height: width,
    rowBytes: rowBytes,
    pixelFormat: format,
  );
  if (!allowUpscaling) {
    if (targetWidth != null && targetWidth > descriptor.width) {
      targetWidth = descriptor.width;
    }
    if (targetHeight != null && targetHeight > descriptor.height) {
      targetHeight = descriptor.height;
    }
  }

  final ui.Codec codec = await descriptor.instantiateCodec(
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );

  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  codec.dispose();
  buffer.dispose();
  descriptor.dispose();
  return frameInfo.image;
}

Uint8List rotateImageArbitrary(Uint8List pixels, int width, int height, int rotationAngle) {
  double angle = rotationAngle * pi / 180.0;
  int newWidth = rotationAngle % 180 == 0 ? width : height;
  int newHeight = rotationAngle % 180 == 0 ? height : width;

  Uint8List rotatedImageData = Uint8List(pixels.length);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int sourceIndex = (y * width + x) * 4;

      // Calculate new coordinates after rotation
      int centerX = width ~/ 2;
      int centerY = height ~/ 2;
      int offsetX = x - centerX;
      int offsetY = y - centerY;
      int rotatedX = (offsetX * cos(angle) - offsetY * sin(angle)).round() + centerX;
      int rotatedY = (offsetX * sin(angle) + offsetY * cos(angle)).round() + centerY;

      if (rotatedX >= 0 && rotatedX < newWidth && rotatedY >= 0 && rotatedY < newHeight) {
        int targetIndex = (rotatedY * newWidth + rotatedX) * 4;

        rotatedImageData[targetIndex] = pixels[sourceIndex];
        rotatedImageData[targetIndex + 1] = pixels[sourceIndex + 1];
        rotatedImageData[targetIndex + 2] = pixels[sourceIndex + 2];
        rotatedImageData[targetIndex + 3] = pixels[sourceIndex + 3];
      }
    }
  }

  return rotatedImageData;
}

class ImagePainter extends CustomPainter {
  ImagePainter({
    required this.image,
    required this.x,
    required this.y,
    required this.scale,
  });

  ui.Image? image;
  double x;
  double y;
  double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    if (x.isNaN || y.isNaN) return;
    canvas.scale(scale, scale);
    // https://github.com/flutter/flutter/issues/76187#issuecomment-784628161
    // https://api.flutter-io.cn/flutter/dart-ui/FilterQuality.html
    var paint = Paint();
    if ((scale - 1.0).abs() > 0.001) {
      paint.filterQuality = FilterQuality.medium;
      if (scale > 10.00000) {
        paint.filterQuality = FilterQuality.high;
      }
    }

    canvas.drawImage(image!, Offset(x.toInt().toDouble(), y.toInt().toDouble()), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
