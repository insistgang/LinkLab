import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'bloc/auth_bloc.dart';
import 'constants/theme.dart';
import 'router.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(AuthCheckRequested()),
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = AppRouter.getRouter(authBloc);

          return MaterialApp.router(
            title: 'LinkLab 運營後臺',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 600, name: MOBILE),
                const Breakpoint(start: 601, end: 900, name: TABLET),
                const Breakpoint(start: 901, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
