import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/theme/app_theme.dart';
import 'config/app_config.dart';
import 'services/demo/demo_data_loader.dart';
import 'services/app_session_service.dart';

/// 演示模式入口
/// 用于竞赛演示，使用模拟数据
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AGENTS.md §4.2 / §8：竞赛版启动时先显式强制 demoMode=true，
  // 再锁定 Demo-only，避免真实依赖阻塞 3 分钟演示闭环。
  // AGENTS.md §4.4：若未来启用真实 Supabase，根目录 supabase/ 才是唯一 schema source of truth，
  // linklab/supabase 历史目录不得再作为初始化依据。
  AppConfig.demoMode = true;
  AppConfig.lockCompetitionDemoMode();
  assert(AppConfig.isCompetitionDemoOnly, '竞赛版必须锁定 Demo-only');
  assert(AppConfig.demoMode, '竞赛版必须强制开启 demoMode');
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
  await AppSessionService.instance.initialize();

  // AGENTS.md 要求全局提供 Riverpod 容器。
  // 竞赛版仍强制走 Demo 主线，但所有 Consumer 页面必须有统一状态作用域。
  runApp(const ProviderScope(child: LinkLabApp()));
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
//   runApp(
//     const ProviderScope(
//       child: LinkLabApp(),
//     ),
//   );
// }
