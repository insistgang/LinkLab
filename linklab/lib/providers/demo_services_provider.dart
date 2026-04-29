import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/demo/demo_ai_service.dart';
import '../services/demo/demo_matching_service.dart';
import '../services/demo_call_service.dart';

final demoAIServiceProvider = Provider<DemoAIService>((ref) {
  return DemoAIService();
});

final demoMatchingServiceProvider = Provider<DemoMatchingService>((ref) {
  return DemoMatchingService();
});

final demoMatchingEngineProvider = Provider<DemoMatchingEngineService>((ref) {
  return DemoMatchingEngineService();
});

final demoCallServiceProvider = Provider<DemoCallService>((ref) {
  return DemoCallService();
});

final demoSOSServiceProvider = Provider<DemoSOSService>((ref) {
  return DemoSOSService();
});
