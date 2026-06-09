import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'core/utils/logger.dart';
import 'services/app_session_service.dart';
import 'services/demo/demo_data_loader.dart';

Widget buildLinkLabApp() {
  return const ProviderScope(child: LinkLabApp());
}

/// 兼容舊測試入口。當前默認啓動鎖定競賽 Demo 主線。
Widget buildCompetitionDemoApp() => buildLinkLabApp();

Future<void> initializeLinkLabApp({
  bool preferRealMode = false,
  bool enablePresenterSessionOnFallback = true,
  bool enableAuthAutoRefresh = true,
}) async {
  await _loadDotEnv();
  AppConfig.configureFromEnvironment(
    dotenv.env,
    preferRealMode: preferRealMode,
    enablePresenterSessionOnFallback: enablePresenterSessionOnFallback,
  );

  if (AppConfig.isRealMode) {
    final initialized = await _initializeSupabase(
      enableAuthAutoRefresh: enableAuthAutoRefresh,
    );
    if (!initialized) {
      AppConfig.configureDemoFallback(
        reason: 'Supabase.initialize 失敗',
        enablePresenterSession: enablePresenterSessionOnFallback,
      );
    }
  }

  // Demo 數據作爲 fallback 資產始終可用；默認啓動不觸發真實業務表查詢。
  await DemoDataLoader.initialize();

  // 注意：此處 ProviderScope 尚未創建，只能直接操作底層服務實例。
  // Riverpod provider 在 runApp 後由 AppSessionNotifier.build() 自動同步。
  // ignore: deprecated_member_use_from_same_package
  await AppSessionService.instance.initialize();

  if (AppConfig.presenterMode) {
    // ignore: deprecated_member_use_from_same_package
    await AppSessionService.instance.ensureCompetitionPresenterSession();
  }
}

/// 顯式 Demo 初始化入口，供閉環測試和現場 fallback 使用。
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
    AppLogger.info('.env 加載完成');
  } catch (error, stackTrace) {
    AppLogger.warning('.env 加載失敗，將按缺少配置處理', error, stackTrace);
  }
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
    AppLogger.error('Supabase client 初始化失敗', error, stackTrace);
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeLinkLabApp();

  // 設置首選方向
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 設置系統UI樣式
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
