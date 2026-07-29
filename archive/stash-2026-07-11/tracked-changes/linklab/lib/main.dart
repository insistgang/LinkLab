import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/api_config.dart';
import 'config/app_config.dart';
import 'core/utils/logger.dart';
import 'services/app_session_service.dart';
import 'services/demo/demo_data_loader.dart';

Widget buildLinkLabApp() {
  return const ProviderScope(child: LinkLabApp());
}

/// 兼容旧测试入口。当前默认启动锁定竞赛 Demo 主线。
Widget buildCompetitionDemoApp() => buildLinkLabApp();

Future<void> initializeLinkLabApp({
  bool preferRealMode = false,
  bool enablePresenterSessionOnFallback = true,
  bool enableAuthAutoRefresh = true,
  bool enableRealAIFromEnvironment = true,
}) async {
  await _loadDotEnv();
  _configureAPIKeysFromEnvironment(dotenv.env);
  AppConfig.configureFromEnvironment(
    dotenv.env,
    preferRealMode: preferRealMode,
    enablePresenterSessionOnFallback: enablePresenterSessionOnFallback,
    enableRealAIFromEnvironment: enableRealAIFromEnvironment,
  );

  if (AppConfig.isRealMode) {
    final initialized = await _initializeSupabase(
      enableAuthAutoRefresh: enableAuthAutoRefresh,
    );
    if (!initialized) {
      AppConfig.configureDemoFallback(
        reason: 'Supabase.initialize 失败',
        enablePresenterSession: enablePresenterSessionOnFallback,
      );
    }
  }

  // Demo 数据作为 fallback 资产始终可用；默认启动不触发真实业务表查询。
  await DemoDataLoader.initialize();

  // 注意：此处 ProviderScope 尚未创建，只能直接操作底层服务实例。
  // Riverpod provider 在 runApp 后由 AppSessionNotifier.build() 自动同步。
  // ignore: deprecated_member_use_from_same_package
  await AppSessionService.instance.initialize();

  if (AppConfig.presenterMode) {
    // ignore: deprecated_member_use_from_same_package
    await AppSessionService.instance.ensureCompetitionPresenterSession();
  }
}

/// 显式 Demo 初始化入口，供闭环测试和现场 fallback 使用。
Future<void> initializeCompetitionDemoApp() async {
  AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: true);
  await DemoDataLoader.initialize();

  // ignore: deprecated_member_use_from_same_package
  await AppSessionService.instance.initialize();
  // ignore: deprecated_member_use_from_same_package
  await AppSessionService.instance.ensureCompetitionPresenterSession();
}

Future<void> _loadDotEnv() async {
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.info('.env 加载完成');
  } catch (error, stackTrace) {
    AppLogger.warning('.env 加载失败，将按缺少配置处理', error, stackTrace);
  }
}

void _configureAPIKeysFromEnvironment(Map<String, String> env) {
  APIConfig.initialize(
    baiduOcrKey: _envValue(env, 'BAIDU_OCR_API_KEY'),
    baiduOcrSecret: _envValue(env, 'BAIDU_OCR_SECRET_KEY'),
    qwenKey: _envValue(env, 'QWEN_API_KEY'),
    xfyunApp: _envValue(env, 'XFYUN_APP_ID'),
    xfyunKey: _envValue(env, 'XFYUN_API_KEY'),
    xfyunSecret: _envValue(env, 'XFYUN_API_SECRET'),
    translateAppId: _envValue(env, 'BAIDU_TRANSLATE_APP_ID'),
    translateSecret: _envValue(env, 'BAIDU_TRANSLATE_SECRET'),
    zhipuKey: _envValue(env, 'ZHIPU_API_KEY'),
    minimaxKey: _envValue(env, 'MINIMAX_API_KEY'),
  );
}

String? _envValue(Map<String, String> env, String key) {
  final value = env[key]?.trim();
  if (value == null || value.isEmpty || value.startsWith('YOUR_')) {
    return null;
  }
  return value;
}

Future<bool> _initializeSupabase({required bool enableAuthAutoRefresh}) async {
  if (!AppConfig.canInitializeSupabase) {
    return false;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: enableAuthAutoRefresh,
        detectSessionInUri: false,
      ),
    );
    AppConfig.markSupabaseInitialized();
    AppLogger.info('Supabase client 初始化完成');
    return true;
  } catch (error, stackTrace) {
    AppConfig.markSupabaseUnavailable();
    AppLogger.error('Supabase client 初始化失败', error, stackTrace);
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeLinkLabApp();

  // 设置首选方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // AGENTS.md 要求全局提供 Riverpod 容器。
  runApp(buildLinkLabApp());
}
