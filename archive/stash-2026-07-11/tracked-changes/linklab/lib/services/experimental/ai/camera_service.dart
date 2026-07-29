import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 相机服务
/// 负责拍照、相册选择、图片压缩和预处理
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// 拍照
  Future<CameraResult?> takePhoto({
    int imageQuality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (photo == null) return null;

      return CameraResult(
        path: photo.path,
        source: ImageSource.camera,
      );
    } catch (e) {
      throw CameraException('拍照失败: $e');
    }
  }

  /// 从相册选择
  Future<CameraResult?> pickFromGallery({
    int imageQuality = 85,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (image == null) return null;

      return CameraResult(
        path: image.path,
        source: ImageSource.gallery,
      );
    } catch (e) {
      throw CameraException('选择图片失败: $e');
    }
  }

  /// 压缩图片
  Future<String> compressImage(
    String imagePath, {
    int quality = 85,
    int maxWidth = 1280,
    int maxHeight = 1280,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) {
        throw CameraException('无法解析图片');
      }

      // 调整大小
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height >= image.width ? maxHeight : null,
        );
      }

      // 压缩并保存
      final compressedBytes = img.encodeJpg(image, quality: quality);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedPath = path.join(tempDir.path, fileName);

      await File(compressedPath).writeAsBytes(compressedBytes);

      return compressedPath;
    } catch (e) {
      throw CameraException('图片压缩失败: $e');
    }
  }

  /// 压缩图片到指定大小以下（用于API上传）
  Future<String> compressToSize(
    String imagePath, {
    int maxSizeKB = 500,
  }) async {
    var quality = 85;
    var compressedPath = imagePath;

    while (quality > 20) {
      compressedPath = await compressImage(
        imagePath,
        quality: quality,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      final file = File(compressedPath);
      final sizeInKB = await file.length() ~/ 1024;

      if (sizeInKB <= maxSizeKB) {
        break;
      }

      quality -= 15;
    }

    return compressedPath;
  }

  /// 裁剪图片中心区域
  Future<String> cropCenter(String imagePath, {double ratio = 0.8}) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw CameraException('无法解析图片');
      }

      final cropWidth = (image.width * ratio).toInt();
      final cropHeight = (image.height * ratio).toInt();
      final x = (image.width - cropWidth) ~/ 2;
      final y = (image.height - cropHeight) ~/ 2;

      final cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: cropWidth,
        height: cropHeight,
      );

      final croppedBytes = img.encodeJpg(cropped, quality: 90);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedPath = path.join(tempDir.path, fileName);

      await File(croppedPath).writeAsBytes(croppedBytes);

      return croppedPath;
    } catch (e) {
      throw CameraException('图片裁剪失败: $e');
    }
  }

  /// 获取图片信息
  Future<ImageInfo> getImageInfo(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw CameraException('无法解析图片');
    }

    final fileSize = await file.length();

    return ImageInfo(
      path: imagePath,
      width: image.width,
      height: image.height,
      sizeInBytes: fileSize,
      format: path.extension(imagePath).toLowerCase(),
    );
  }

  /// 删除临时图片
  Future<void> deleteTempImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略删除错误
    }
  }

  /// 清理所有临时图片
  Future<void> clearTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = await tempDir
          .list()
          .where((f) =>
              f is File &&
              (f.path.endsWith('.jpg') ||
                  f.path.endsWith('.jpeg') ||
                  f.path.endsWith('.png')))
          .toList();

      for (final file in files) {
        await file.delete();
      }
    } catch (e) {
      // 忽略清理错误
    }
  }
}

/// 相机结果
class CameraResult {
  final String path;
  final ImageSource source;

  const CameraResult({
    required this.path,
    required this.source,
  });
}

/// 图片信息
class ImageInfo {
  final String path;
  final int width;
  final int height;
  final int sizeInBytes;
  final String format;

  const ImageInfo({
    required this.path,
    required this.width,
    required this.height,
    required this.sizeInBytes,
    required this.format,
  });

  double get sizeInKB => sizeInBytes / 1024;
  double get sizeInMB => sizeInBytes / (1024 * 1024);
  double get aspectRatio => width / height;
}

/// 相机异常
class CameraException implements Exception {
  final String message;

  CameraException(this.message);

  @override
  String toString() => 'CameraException: $message';
}
