import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'config/app_config.dart';
import 'services/demo/demo_data_loader.dart';

/// 演示模式入口
/// 用于竞赛演示，使用模拟数据
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 显式设置为演示模式（确保不依赖外部服务）
  AppConfig.setDemoMode();
  assert(AppConfig.isDemoMode, '演示模式必须开启');

  // 设置首选方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppTheme.primaryColor,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 加载演示数据
  await DemoDataLoader.initialize();

  runApp(const LinkLabApp());
}

/// 生产模式入口（未来使用）
/// 用于真实环境，连接Supabase和真实API
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // 初始化Supabase
//   await Supabase.initialize(
//     url: AppConstants.supabaseUrl,
//     anonKey: AppConstants.supabaseAnonKey,
//   );
//
//   // 初始化Firebase
//   await Firebase.initializeApp();
//
//   // 初始化TTS
//   await TTSService().initialize();
//
//   runApp(const LinkLabApp());
// }
