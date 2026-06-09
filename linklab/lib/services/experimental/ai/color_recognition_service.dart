import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'ai_service.dart';

/// 顏色識別服務
/// F4 顏色識別的核心實現
/// 使用本地圖像處理算法，支持離線使用
class ColorRecognitionService implements AIService {
  // 顏色數據庫（支持色盲友好描述）
  static final List<ColorInfo> _colorDatabase = [
    // 基礎色
    ColorInfo(name: '紅色', nameForColorBlind: '暖色調，類似番茄的顏色', r: 255, g: 0, b: 0),
    ColorInfo(name: '深紅', nameForColorBlind: '深暖色調，類似磚塊的顏色', r: 139, g: 0, b: 0),
    ColorInfo(name: '粉紅', nameForColorBlind: '淺暖色調，類似櫻花的顏色', r: 255, g: 192, b: 203),
    ColorInfo(name: '橙色', nameForColorBlind: '暖色調，類似橙子的顏色', r: 255, g: 165, b: 0),
    ColorInfo(name: '黃色', nameForColorBlind: '明亮暖色調，類似檸檬的顏色', r: 255, g: 255, b: 0),
    ColorInfo(name: '金色', nameForColorBlind: '明亮暖色調，類似陽光的顏色', r: 255, g: 215, b: 0),
    ColorInfo(name: '綠色', nameForColorBlind: '冷色調，類似草地的顏色', r: 0, g: 128, b: 0),
    ColorInfo(name: '淺綠', nameForColorBlind: '淺冷色調，類似嫩芽的顏色', r: 144, g: 238, b: 144),
    ColorInfo(name: '深綠', nameForColorBlind: '深冷色調，類似森林的顏色', r: 0, g: 100, b: 0),
    ColorInfo(name: '青色', nameForColorBlind: '冷色調，類似海水的顏色', r: 0, g: 255, b: 255),
    ColorInfo(name: '藍色', nameForColorBlind: '冷色調，類似天空的顏色', r: 0, g: 0, b: 255),
    ColorInfo(name: '天藍', nameForColorBlind: '淺冷色調，類似晴天的顏色', r: 135, g: 206, b: 235),
    ColorInfo(name: '深藍', nameForColorBlind: '深冷色調，類似深海的顏色', r: 0, g: 0, b: 139),
    ColorInfo(name: '紫色', nameForColorBlind: '中性色調，類似葡萄的顏色', r: 128, g: 0, b: 128),
    ColorInfo(name: '品紅', nameForColorBlind: '暖色調，類似花朵的顏色', r: 255, g: 0, b: 255),
    // 中性色
    ColorInfo(name: '白色', nameForColorBlind: '很淺的色調，類似雪的顏色', r: 255, g: 255, b: 255),
    ColorInfo(name: '淺灰', nameForColorBlind: '淺色調，類似雲的顏色', r: 192, g: 192, b: 192),
    ColorInfo(name: '灰色', nameForColorBlind: '中等色調，類似石頭的顏色', r: 128, g: 128, b: 128),
    ColorInfo(name: '深灰', nameForColorBlind: '深色調，類似煤炭的顏色', r: 64, g: 64, b: 64),
    ColorInfo(name: '黑色', nameForColorBlind: '很深的色調，類似夜晚的顏色', r: 0, g: 0, b: 0),
    // 棕色系
    ColorInfo(name: '棕色', nameForColorBlind: '深暖色調，類似木頭的顏色', r: 165, g: 42, b: 42),
    ColorInfo(name: '米色', nameForColorBlind: '淺暖色調，類似沙子的顏色', r: 245, g: 245, b: 220),
    ColorInfo(name: '咖啡色', nameForColorBlind: '深暖色調，類似咖啡豆的顏色', r: 111, g: 78, b: 55),
    // 常見顏色
    ColorInfo(name: '膚色', nameForColorBlind: '暖色調，類似皮膚的顏色', r: 255, g: 224, b: 189),
    ColorInfo(name: '海軍藍', nameForColorBlind: '深冷色調，類似制服的顏色', r: 0, g: 0, b: 128),
    ColorInfo(name: '橄欖綠', nameForColorBlind: '中性色調，類似橄欖的顏色', r: 128, g: 128, b: 0),
    ColorInfo(name: '桃色', nameForColorBlind: '淺暖色調，類似桃子的顏色', r: 255, g: 218, b: 185),
    ColorInfo(name: '薰衣草紫', nameForColorBlind: '淺中性色調，類似花的顏色', r: 230, g: 230, b: 250),
  ];

  @override
  String get serviceName => 'ColorRecognitionService';

  @override
  Future<bool> isAvailable() async {
    // 本地服務總是可用
    return true;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    if (imageUrl == null) {
      return AIResponse.error('顏色識別需要圖片輸入');
    }

    try {
      // 1. 讀取圖片
      final imageFile = File(imageUrl);
      if (!await imageFile.exists()) {
        return AIResponse.error('圖片文件不存在');
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return AIResponse.error('無法解析圖片');
      }

      // 2. 提取主色調
      final dominantColors = _extractDominantColors(image, count: 3);

      // 3. 匹配顏色名稱
      final colorResults = dominantColors.map((c) => _matchColor(c)).toList();

      // 4. 生成響應
      final responseText = _buildResponse(colorResults);

      return AIResponse(
        text: responseText,
        intent: IntentType.colorRecognition,
        urgency: UrgencyLevel.normal,
        needsHuman: false,
        confidence: colorResults.isNotEmpty ? colorResults.first.confidence : 0.0,
        extraData: {
          'colors': colorResults.map((c) => {
            'name': c.colorInfo.name,
            'rgb': [c.rgb.r, c.rgb.g, c.rgb.b],
            'percentage': c.percentage,
          }).toList(),
        },
      );
    } catch (e) {
      return AIResponse.error('顏色識別失敗: $e');
    }
  }

  /// 提取主色調
  List<ColorWithPercentage> _extractDominantColors(img.Image image, {required int count}) {
    // 採樣像素（爲提高性能，進行降採樣）
    final sampleStep = math.max(1, (image.width * image.height ~/ 10000));
    final colorMap = <int, int>{}; // 顏色 -> 出現次數

    for (var y = 0; y < image.height; y += sampleStep) {
      for (var x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        // 量化顏色（減少顏色數量）
        final quantized = _quantizeColor(pixel.r, pixel.g, pixel.b);
        colorMap[quantized] = (colorMap[quantized] ?? 0) + 1;
      }
    }

    // 按出現頻率排序
    final sortedColors = colorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 合併相似顏色
    final dominantColors = <ColorWithPercentage>[];
    for (final entry in sortedColors) {
      final rgb = _intToRgb(entry.key);

      // 檢查是否與已選顏色相似
      bool isSimilar = false;
      for (final selected in dominantColors) {
        if (_colorDistance(rgb, selected.rgb) < 30) {
          isSimilar = true;
          break;
        }
      }

      if (!isSimilar) {
        final percentage = entry.value * sampleStep * sampleStep / (image.width * image.height);
        dominantColors.add(ColorWithPercentage(
          rgb: rgb,
          percentage: percentage,
        ));

        if (dominantColors.length >= count) break;
      }
    }

    return dominantColors;
  }

  /// 量化顏色（減少顏色空間）
  int _quantizeColor(int r, int g, int b) {
    // 將每個通道量化爲8個級別
    final qr = (r ~/ 32) * 32;
    final qg = (g ~/ 32) * 32;
    final qb = (b ~/ 32) * 32;
    return (qr << 16) | (qg << 8) | qb;
  }

  /// int轉RGB
  RGB _intToRgb(int value) {
    return RGB(
      r: (value >> 16) & 0xFF,
      g: (value >> 8) & 0xFF,
      b: value & 0xFF,
    );
  }

  /// 計算顏色距離（歐幾里得距離）
  double _colorDistance(RGB c1, RGB c2) {
    final dr = c1.r - c2.r;
    final dg = c1.g - c2.g;
    final db = c1.b - c2.b;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  /// 匹配顏色名稱
  ColorMatchResult _matchColor(ColorWithPercentage color) {
    ColorInfo? bestMatch;
    double minDistance = double.infinity;

    for (final colorInfo in _colorDatabase) {
      final distance = _colorDistance(
        color.rgb,
        RGB(r: colorInfo.r, g: colorInfo.g, b: colorInfo.b),
      );

      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = colorInfo;
      }
    }

    // 計算置信度（距離越小，置信度越高）
    final confidence = math.max(0, 1 - minDistance / 441.7); // 441.7 = sqrt(255^2 * 3)

    return ColorMatchResult(
      colorInfo: bestMatch ?? _colorDatabase[10], // 默認藍色
      rgb: color.rgb,
      confidence: confidence,
      percentage: color.percentage,
    );
  }

  /// 構建響應文本
  String _buildResponse(List<ColorMatchResult> colors) {
    if (colors.isEmpty) {
      return '未能識別顏色，請嘗試重新拍攝。';
    }

    final buffer = StringBuffer();
    final mainColor = colors.first;

    buffer.writeln('主要顏色是${mainColor.colorInfo.name}。');
    buffer.writeln();
    buffer.writeln('色盲友好描述：${mainColor.colorInfo.nameForColorBlind}。');

    if (colors.length > 1) {
      buffer.writeln();
      buffer.writeln('圖片中還包含：');
      for (var i = 1; i < colors.length && i < 3; i++) {
        final color = colors[i];
        if (color.percentage > 0.1) { // 只顯示佔比超過10%的顏色
          buffer.writeln('• ${color.colorInfo.name}（約佔${(color.percentage * 100).toInt()}%）');
        }
      }
    }

    // 添加顏色搭配建議
    if (colors.length >= 2) {
      buffer.writeln();
      buffer.writeln(_getColorCombinationAdvice(colors));
    }

    return buffer.toString();
  }

  /// 獲取顏色搭配建議
  String _getColorCombinationAdvice(List<ColorMatchResult> colors) {
    final mainColor = colors[0].colorInfo.name;
    final secondaryColor = colors.length > 1 ? colors[1].colorInfo.name : null;

    if (secondaryColor != null) {
      return '這是$mainColor和$secondaryColor的搭配。';
    }

    return '這是純色$mainColor。';
  }

  /// 識別特定區域的顏色（用於衣物等）
  Future<AIResponse> recognizeRegion(
    String imageUrl, {
    required Region region,
    bool colorBlindFriendly = true,
  }) async {
    try {
      final imageFile = File(imageUrl);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return AIResponse.error('無法解析圖片');
      }

      // 提取指定區域的顏色
      final regionColor = _extractRegionColor(image, region);
      final match = _matchColor(ColorWithPercentage(rgb: regionColor, percentage: 1.0));

      final responseText = colorBlindFriendly
          ? '這個區域是${match.colorInfo.name}，${match.colorInfo.nameForColorBlind}。'
          : '這個區域是${match.colorInfo.name}。';

      return AIResponse(
        text: responseText,
        intent: IntentType.colorRecognition,
        confidence: match.confidence,
        extraData: {
          'region': region.toString(),
          'color': match.colorInfo.name,
          'rgb': [match.rgb.r, match.rgb.g, match.rgb.b],
        },
      );
    } catch (e) {
      return AIResponse.error('區域顏色識別失敗: $e');
    }
  }

  /// 提取指定區域的顏色
  RGB _extractRegionColor(img.Image image, Region region) {
    final x = (region.x * image.width).toInt();
    final y = (region.y * image.height).toInt();
    final w = (region.width * image.width).toInt();
    final h = (region.height * image.height).toInt();

    var totalR = 0, totalG = 0, totalB = 0, count = 0;

    for (var dy = y; dy < y + h && dy < image.height; dy++) {
      for (var dx = x; dx < x + w && dx < image.width; dx++) {
        final pixel = image.getPixel(dx, dy);
        totalR += pixel.r;
        totalG += pixel.g;
        totalB += pixel.b;
        count++;
      }
    }

    if (count == 0) return RGB(r: 128, g: 128, b: 128);

    return RGB(
      r: totalR ~/ count,
      g: totalG ~/ count,
      b: totalB ~/ count,
    );
  }
}

/// 顏色信息
class ColorInfo {
  final String name;
  final String nameForColorBlind;
  final int r;
  final int g;
  final int b;

  const ColorInfo({
    required this.name,
    required this.nameForColorBlind,
    required this.r,
    required this.g,
    required this.b,
  });
}

/// RGB顏色
class RGB {
  final int r;
  final int g;
  final int b;

  const RGB({required this.r, required this.g, required this.b});
}

/// 帶佔比的顏色
class ColorWithPercentage {
  final RGB rgb;
  final double percentage;

  const ColorWithPercentage({required this.rgb, required this.percentage});
}

/// 顏色匹配結果
class ColorMatchResult {
  final ColorInfo colorInfo;
  final RGB rgb;
  final double confidence;
  final double percentage;

  const ColorMatchResult({
    required this.colorInfo,
    required this.rgb,
    required this.confidence,
    required this.percentage,
  });
}

/// 圖片區域（歸一化座標 0-1）
class Region {
  final double x;
  final double y;
  final double width;
  final double height;

  const Region({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'Region(x: $x, y: $y, w: $width, h: $height)';
}
