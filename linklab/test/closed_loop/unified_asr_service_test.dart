@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:linklab/services/asr/unified_asr_service.dart';

void main() {
  group('UnifiedAsrService local speech completion', () {
    test('treats Web Speech terminal statuses as completion signals', () {
      expect(UnifiedAsrService.isTerminalSpeechStatus('notListening'), isTrue);
      expect(UnifiedAsrService.isTerminalSpeechStatus('done'), isTrue);
      expect(UnifiedAsrService.isTerminalSpeechStatus('doneNoResult'), isTrue);
      expect(UnifiedAsrService.isTerminalSpeechStatus('listening'), isFalse);
    });

    test('keeps partial recognition text usable as final input', () {
      expect(
        UnifiedAsrService.normalizeRecognizedText('  帮我   读药品盒  '),
        '帮我 读药品盒',
      );
    });
  });
}
