import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 相機服務
/// 負責拍照、相冊選擇、圖片壓縮和預處理
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
      throw CameraException('拍照失敗: $e');
    }
  }

  /// 從相冊選擇
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
      throw CameraException('選擇圖片失敗: $e');
    }
  }

  /// 壓縮圖片
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
        throw CameraException('無法解析圖片');
      }

      // 調整大小
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height >= image.width ? maxHeight : null,
        );
      }

      // 壓縮並保存
      final compressedBytes = img.encodeJpg(image, quality: quality);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedPath = path.join(tempDir.path, fileName);

      await File(compressedPath).writeAsBytes(compressedBytes);

      return compressedPath;
    } catch (e) {
      throw CameraException('圖片壓縮失敗: $e');
    }
  }

  /// 壓縮圖片到指定大小以下（用於API上傳）
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

  /// 裁剪圖片中心區域
  Future<String> cropCenter(String imagePath, {double ratio = 0.8}) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw CameraException('無法解析圖片');
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
      throw CameraException('圖片裁剪失敗: $e');
    }
  }

  /// 獲取圖片信息
  Future<ImageInfo> getImageInfo(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw CameraException('無法解析圖片');
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

  /// 刪除臨時圖片
  Future<void> deleteTempImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略刪除錯誤
    }
  }

  /// 清理所有臨時圖片
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
      // 忽略清理錯誤
    }
  }
}

/// 相機結果
class CameraResult {
  final String path;
  final ImageSource source;

  const CameraResult({
    required this.path,
    required this.source,
  });
}

/// 圖片信息
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

/// 相機異常
class CameraException implements Exception {
  final String message;

  CameraException(this.message);

  @override
  String toString() => 'CameraException: $message';
}
