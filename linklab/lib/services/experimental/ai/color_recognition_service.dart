import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'ai_service.dart';

/// 颜色识别服务
/// F4 颜色识别的核心实现
/// 使用本地图像处理算法，支持离线使用
class ColorRecognitionService implements AIService {
  // 颜色数据库（支持色盲友好描述）
  static final List<ColorInfo> _colorDatabase = [
    // 基础色
    ColorInfo(name: '红色', nameForColorBlind: '暖色调，类似番茄的颜色', r: 255, g: 0, b: 0),
    ColorInfo(name: '深红', nameForColorBlind: '深暖色调，类似砖块的颜色', r: 139, g: 0, b: 0),
    ColorInfo(name: '粉红', nameForColorBlind: '浅暖色调，类似樱花的颜色', r: 255, g: 192, b: 203),
    ColorInfo(name: '橙色', nameForColorBlind: '暖色调，类似橙子的颜色', r: 255, g: 165, b: 0),
    ColorInfo(name: '黄色', nameForColorBlind: '明亮暖色调，类似柠檬的颜色', r: 255, g: 255, b: 0),
    ColorInfo(name: '金色', nameForColorBlind: '明亮暖色调，类似阳光的颜色', r: 255, g: 215, b: 0),
    ColorInfo(name: '绿色', nameForColorBlind: '冷色调，类似草地的颜色', r: 0, g: 128, b: 0),
    ColorInfo(name: '浅绿', nameForColorBlind: '浅冷色调，类似嫩芽的颜色', r: 144, g: 238, b: 144),
    ColorInfo(name: '深绿', nameForColorBlind: '深冷色调，类似森林的颜色', r: 0, g: 100, b: 0),
    ColorInfo(name: '青色', nameForColorBlind: '冷色调，类似海水的颜色', r: 0, g: 255, b: 255),
    ColorInfo(name: '蓝色', nameForColorBlind: '冷色调，类似天空的颜色', r: 0, g: 0, b: 255),
    ColorInfo(name: '天蓝', nameForColorBlind: '浅冷色调，类似晴天的颜色', r: 135, g: 206, b: 235),
    ColorInfo(name: '深蓝', nameForColorBlind: '深冷色调，类似深海的颜色', r: 0, g: 0, b: 139),
    ColorInfo(name: '紫色', nameForColorBlind: '中性色调，类似葡萄的颜色', r: 128, g: 0, b: 128),
    ColorInfo(name: '品红', nameForColorBlind: '暖色调，类似花朵的颜色', r: 255, g: 0, b: 255),
    // 中性色
    ColorInfo(name: '白色', nameForColorBlind: '很浅的色调，类似雪的颜色', r: 255, g: 255, b: 255),
    ColorInfo(name: '浅灰', nameForColorBlind: '浅色调，类似云的颜色', r: 192, g: 192, b: 192),
    ColorInfo(name: '灰色', nameForColorBlind: '中等色调，类似石头的颜色', r: 128, g: 128, b: 128),
    ColorInfo(name: '深灰', nameForColorBlind: '深色调，类似煤炭的颜色', r: 64, g: 64, b: 64),
    ColorInfo(name: '黑色', nameForColorBlind: '很深的色调，类似夜晚的颜色', r: 0, g: 0, b: 0),
    // 棕色系
    ColorInfo(name: '棕色', nameForColorBlind: '深暖色调，类似木头的颜色', r: 165, g: 42, b: 42),
    ColorInfo(name: '米色', nameForColorBlind: '浅暖色调，类似沙子的颜色', r: 245, g: 245, b: 220),
    ColorInfo(name: '咖啡色', nameForColorBlind: '深暖色调，类似咖啡豆的颜色', r: 111, g: 78, b: 55),
    // 常见颜色
    ColorInfo(name: '肤色', nameForColorBlind: '暖色调，类似皮肤的颜色', r: 255, g: 224, b: 189),
    ColorInfo(name: '海军蓝', nameForColorBlind: '深冷色调，类似制服的颜色', r: 0, g: 0, b: 128),
    ColorInfo(name: '橄榄绿', nameForColorBlind: '中性色调，类似橄榄的颜色', r: 128, g: 128, b: 0),
    ColorInfo(name: '桃色', nameForColorBlind: '浅暖色调，类似桃子的颜色', r: 255, g: 218, b: 185),
    ColorInfo(name: '薰衣草紫', nameForColorBlind: '浅中性色调，类似花的颜色', r: 230, g: 230, b: 250),
  ];

  @override
  String get serviceName => 'ColorRecognitionService';

  @override
  Future<bool> isAvailable() async {
    // 本地服务总是可用
    return true;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    if (imageUrl == null) {
      return AIResponse.error('颜色识别需要图片输入');
    }

    try {
      // 1. 读取图片
      final imageFile = File(imageUrl);
      if (!await imageFile.exists()) {
        return AIResponse.error('图片文件不存在');
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        return AIResponse.error('无法解析图片');
      }

      // 2. 提取主色调
      final dominantColors = _extractDominantColors(image, count: 3);

      // 3. 匹配颜色名称
      final colorResults = dominantColors.map((c) => _matchColor(c)).toList();

      // 4. 生成响应
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
      return AIResponse.error('颜色识别失败: $e');
    }
  }

  /// 提取主色调
  List<ColorWithPercentage> _extractDominantColors(img.Image image, {required int count}) {
    // 采样像素（为提高性能，进行降采样）
    final sampleStep = math.max(1, (image.width * image.height ~/ 10000));
    final colorMap = <int, int>{}; // 颜色 -> 出现次数

    for (var y = 0; y < image.height; y += sampleStep) {
      for (var x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        // 量化颜色（减少颜色数量）
        final quantized = _quantizeColor(pixel.r, pixel.g, pixel.b);
        colorMap[quantized] = (colorMap[quantized] ?? 0) + 1;
      }
    }

    // 按出现频率排序
    final sortedColors = colorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 合并相似颜色
    final dominantColors = <ColorWithPercentage>[];
    for (final entry in sortedColors) {
      final rgb = _intToRgb(entry.key);

      // 检查是否与已选颜色相似
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

  /// 量化颜色（减少颜色空间）
  int _quantizeColor(int r, int g, int b) {
    // 将每个通道量化为8个级别
    final qr = (r ~/ 32) * 32;
    final qg = (g ~/ 32) * 32;
    final qb = (b ~/ 32) * 32;
    return (qr << 16) | (qg << 8) | qb;
  }

  /// int转RGB
  RGB _intToRgb(int value) {
    return RGB(
      r: (value >> 16) & 0xFF,
      g: (value >> 8) & 0xFF,
      b: value & 0xFF,
    );
  }

  /// 计算颜色距离（欧几里得距离）
  double _colorDistance(RGB c1, RGB c2) {
    final dr = c1.r - c2.r;
    final dg = c1.g - c2.g;
    final db = c1.b - c2.b;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  /// 匹配颜色名称
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

    // 计算置信度（距离越小，置信度越高）
    final confidence = math.max(0, 1 - minDistance / 441.7); // 441.7 = sqrt(255^2 * 3)

    return ColorMatchResult(
      colorInfo: bestMatch ?? _colorDatabase[10], // 默认蓝色
      rgb: color.rgb,
      confidence: confidence,
      percentage: color.percentage,
    );
  }

  /// 构建响应文本
  String _buildResponse(List<ColorMatchResult> colors) {
    if (colors.isEmpty) {
      return '未能识别颜色，请尝试重新拍摄。';
    }

    final buffer = StringBuffer();
    final mainColor = colors.first;

    buffer.writeln('主要颜色是${mainColor.colorInfo.name}。');
    buffer.writeln();
    buffer.writeln('色盲友好描述：${mainColor.colorInfo.nameForColorBlind}。');

    if (colors.length > 1) {
      buffer.writeln();
      buffer.writeln('图片中还包含：');
      for (var i = 1; i < colors.length && i < 3; i++) {
        final color = colors[i];
        if (color.percentage > 0.1) { // 只显示占比超过10%的颜色
          buffer.writeln('• ${color.colorInfo.name}（约占${(color.percentage * 100).toInt()}%）');
        }
      }
    }

    // 添加颜色搭配建议
    if (colors.length >= 2) {
      buffer.writeln();
      buffer.writeln(_getColorCombinationAdvice(colors));
    }

    return buffer.toString();
  }

  /// 获取颜色搭配建议
  String _getColorCombinationAdvice(List<ColorMatchResult> colors) {
    final mainColor = colors[0].colorInfo.name;
    final secondaryColor = colors.length > 1 ? colors[1].colorInfo.name : null;

    if (secondaryColor != null) {
      return '这是$mainColor和$secondaryColor的搭配。';
    }

    return '这是纯色$mainColor。';
  }

  /// 识别特定区域的颜色（用于衣物等）
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
        return AIResponse.error('无法解析图片');
      }

      // 提取指定区域的颜色
      final regionColor = _extractRegionColor(image, region);
      final match = _matchColor(ColorWithPercentage(rgb: regionColor, percentage: 1.0));

      final responseText = colorBlindFriendly
          ? '这个区域是${match.colorInfo.name}，${match.colorInfo.nameForColorBlind}。'
          : '这个区域是${match.colorInfo.name}。';

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
      return AIResponse.error('区域颜色识别失败: $e');
    }
  }

  /// 提取指定区域的颜色
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

/// 颜色信息
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

/// RGB颜色
class RGB {
  final int r;
  final int g;
  final int b;

  const RGB({required this.r, required this.g, required this.b});
}

/// 带占比的颜色
class ColorWithPercentage {
  final RGB rgb;
  final double percentage;

  const ColorWithPercentage({required this.rgb, required this.percentage});
}

/// 颜色匹配结果
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

/// 图片区域（归一化座标 0-1）
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
