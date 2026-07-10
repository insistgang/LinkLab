@Tags(['eval'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/config/api_config.dart';
import 'package:linklab/config/app_config.dart';
import 'package:linklab/main.dart' as app_entry;
import 'package:linklab/models/demo_ai_intent.dart';
import 'package:linklab/models/demo_match_request.dart';
import 'package:linklab/models/demo_volunteer.dart' as match_model;
import 'package:linklab/services/demo/demo_data_loader.dart';
import 'package:linklab/services/demo/demo_matching_service.dart';
import 'package:linklab/services/demo_call_service.dart' as call_demo;
import 'package:linklab/services/facades/agent_result.dart';
import 'package:linklab/services/facades/agent_service_facade.dart';
import 'package:linklab/services/local_storage.dart';

LatencyRow? _firstScreenLatency;

void main() {
  testWidgets(
    'LinkAble first screen latency benchmark',
    (tester) async {
      Logger.level = Level.off;
      _resetProgress();
      _markProgress('first_screen:start');
      _firstScreenLatency = await _measureFirstScreen(tester);
      _markProgress('first_screen:done');
      expect(_firstScreenLatency!.samples, hasLength(20));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'LinkAble AI inference evaluation runner',
    () async {
      Logger.level = Level.off;
      final recordedFirstScreenLatency = _firstScreenLatency;
      expect(recordedFirstScreenLatency, isNotNull);
      final firstScreenLatency = recordedFirstScreenLatency!;
      _markProgress('runner:start');
      await _prepareEvalEnvironment();
      _markProgress('runner:environment_ready');

      final intentSamples = _loadSamples('eval/datasets/intent_samples.json');
      final emergencySamples = _loadSamples(
        'eval/datasets/emergency_samples.json',
      );
      final allSamples = [...intentSamples, ...emergencySamples];
      final facade = AgentServiceFacade();

      final intentPredictions = <PredictionRow>[];
      for (final sample in intentSamples) {
        _markProgress('intent:before:${sample.id}');
        intentPredictions.add(await _predictSample(sample, facade));
        _markProgress('intent:after:${sample.id}');
      }
      _markProgress('runner:intent_predictions_done');

      final emergencyPredictions = <PredictionRow>[];
      for (final sample in emergencySamples) {
        _markProgress('emergency:before:${sample.id}');
        emergencyPredictions.add(await _predictSample(sample, facade));
        _markProgress('emergency:after:${sample.id}');
      }
      _markProgress('runner:emergency_predictions_done');

      final labels = _orderedLabels(intentPredictions);
      final classMetrics = _classMetrics(intentPredictions, labels);
      final confusion = _confusionMatrix(intentPredictions, labels);
      final latencyRows = [
        firstScreenLatency,
        ...await _runNonWidgetLatencyBenchmarks(),
      ];
      _markProgress('runner:latency_done');

      final intentAccuracy = _accuracy(
        intentPredictions,
        (row) => row.predIntent == row.sample.goldIntent,
      );
      final actionAccuracy = _accuracy(
        allSamples
            .map(
              (sample) => intentPredictions
                  .followedBy(emergencyPredictions)
                  .firstWhere((row) => row.sample.id == sample.id),
            )
            .toList(),
        (row) => row.predNextAction == row.sample.goldNextAction,
      );
      final easyAccuracy = _accuracy(
        intentPredictions.where((row) => row.sample.subset == 'easy').toList(),
        (row) => row.predIntent == row.sample.goldIntent,
      );
      final hardAccuracy = _accuracy(
        intentPredictions.where((row) => row.sample.subset == 'hard').toList(),
        (row) => row.predIntent == row.sample.goldIntent,
      );

      final emergencyStats = _emergencyStats(emergencyPredictions);
      final misclassified = intentPredictions
          .followedBy(emergencyPredictions)
          .where(
            (row) =>
                row.predIntent != row.sample.goldIntent ||
                row.predUrgency != row.sample.goldUrgency ||
                row.predNextAction != row.sample.goldNextAction,
          )
          .toList();

      final metricsRows = <MetricRow>[
        MetricRow(
          '意图识别总准确率',
          '越高越好；按真实 DemoAiIntent 12 类',
          _pct(intentAccuracy),
          'n=${intentPredictions.length}, DemoMode 规则基线',
        ),
        MetricRow('意图识别 easy 子集准确率', '越高越好', _pct(easyAccuracy), '直接/显式表达样本'),
        MetricRow(
          '意图识别 hard 子集准确率',
          '越高越好',
          _pct(hardAccuracy),
          '改写/隐含表达样本；用于防止关键词自测虚高',
        ),
        MetricRow(
          'next_action 正确率',
          '越高越好',
          _pct(actionAccuracy),
          '覆盖意图集+紧急集, 对比 trigger_sos/match_volunteer/answer/ask_followup',
        ),
        MetricRow(
          '紧急召回率',
          '目标高召回；不得漏 SOS',
          _pct(emergencyStats.recall),
          '${emergencyStats.tp}/${emergencyStats.positiveTotal} 真实紧急被命中',
        ),
        MetricRow(
          '紧急误报率',
          '越低越好',
          _pct(emergencyStats.falsePositiveRate),
          '${emergencyStats.fp}/${emergencyStats.negativeTotal} 非紧急被误判紧急',
        ),
        for (final row in latencyRows)
          MetricRow(
            row.metric,
            '每项>=20次；报 median/p95',
            'median=${row.medianMs.toStringAsFixed(2)}ms; p95=${row.p95Ms.toStringAsFixed(2)}ms',
            row.note,
          ),
      ];

      final resultDir = Directory('eval/results')..createSync(recursive: true);
      _writeCsv(File('${resultDir.path}/inference_metrics.csv'), [
        ['指标', '目标', '实测', '备注'],
        for (final row in metricsRows)
          [row.metric, row.target, row.actual, row.note],
      ]);
      _writeCsv(File('${resultDir.path}/intent_metrics_by_class.csv'), [
        ['class', 'precision', 'recall', 'tp', 'fp', 'fn', 'support'],
        for (final entry in classMetrics.entries)
          [
            entry.key,
            entry.value.precision.toStringAsFixed(6),
            entry.value.recall.toStringAsFixed(6),
            '${entry.value.tp}',
            '${entry.value.fp}',
            '${entry.value.fn}',
            '${entry.value.support}',
          ],
      ]);
      _writeCsv(File('${resultDir.path}/confusion_matrix.csv'), [
        ['gold\\pred', ...labels],
        for (final gold in labels)
          [gold, for (final pred in labels) '${confusion[gold]?[pred] ?? 0}'],
      ]);
      _writeCsv(File('${resultDir.path}/latency_results.csv'), [
        [
          'metric',
          'mode',
          'runs',
          'median_ms',
          'p95_ms',
          'min_ms',
          'max_ms',
          'note',
        ],
        for (final row in latencyRows)
          [
            row.metric,
            row.mode,
            '${row.samples.length}',
            row.medianMs.toStringAsFixed(6),
            row.p95Ms.toStringAsFixed(6),
            row.minMs.toStringAsFixed(6),
            row.maxMs.toStringAsFixed(6),
            row.note,
          ],
      ]);
      _writeCsv(File('${resultDir.path}/misclassified.csv'), [
        [
          'id',
          'subset',
          'text',
          'gold_intent',
          'pred_intent',
          'gold_urgency',
          'pred_urgency',
          'gold_next_action',
          'pred_next_action',
          'note',
        ],
        for (final row in misclassified)
          [
            row.sample.id,
            row.sample.subset,
            row.sample.text,
            row.sample.goldIntent,
            row.predIntent,
            row.sample.goldUrgency,
            row.predUrgency,
            row.sample.goldNextAction,
            row.predNextAction,
            row.sample.note,
          ],
      ]);
      _writeCsv(File('${resultDir.path}/raw_predictions.csv'), [
        [
          'id',
          'dataset',
          'subset',
          'text',
          'gold_intent',
          'pred_intent',
          'gold_urgency',
          'pred_urgency',
          'gold_next_action',
          'pred_next_action',
          'success',
          'confidence',
        ],
        for (final row in intentPredictions.followedBy(emergencyPredictions))
          [
            row.sample.id,
            row.sample.dataset,
            row.sample.subset,
            row.sample.text,
            row.sample.goldIntent,
            row.predIntent,
            row.sample.goldUrgency,
            row.predUrgency,
            row.sample.goldNextAction,
            row.predNextAction,
            '${row.success}',
            row.confidence.toStringAsFixed(6),
          ],
      ]);

      final llmStatus = _llmStatus();
      File(
        '${resultDir.path}/llm_eval_status.txt',
      ).writeAsStringSync('${llmStatus.title}\n${llmStatus.detail}\n');
      File(
        '${resultDir.path}/ARCHITECTURE.md',
      ).writeAsStringSync(_architectureMarkdown(allSamples));
      File('${resultDir.path}/REPORT.md').writeAsStringSync(
        _reportMarkdown(
          metricsRows: metricsRows,
          classMetrics: classMetrics,
          labels: labels,
          confusion: confusion,
          intentPredictions: intentPredictions,
          emergencyPredictions: emergencyPredictions,
          misclassified: misclassified,
          latencyRows: latencyRows,
          llmStatus: llmStatus,
        ),
      );
      _markProgress('runner:reports_written');

      expect(intentPredictions, hasLength(120));
      expect(emergencyPredictions, hasLength(40));
      expect(latencyRows.every((row) => row.samples.length >= 20), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

Future<void> _prepareEvalEnvironment({bool reloadDemoData = false}) async {
  _markProgress('prepare:binding:start');
  TestWidgetsFlutterBinding.ensureInitialized();
  _markProgress('prepare:binding:done');
  _markProgress('prepare:shared_preferences_mock:start');
  SharedPreferences.setMockInitialValues({});
  _markProgress('prepare:shared_preferences_mock:done');
  _markProgress('prepare:app_config:start');
  AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
  _markProgress('prepare:app_config:done');
  if (reloadDemoData) {
    _markProgress('prepare:demo_data_loader:start');
    await DemoDataLoader.initialize();
    _markProgress('prepare:demo_data_loader:done');
  } else {
    _markProgress('prepare:demo_data_loader:reuse_loaded');
  }
  _markProgress('prepare:local_storage_initialize:start');
  final storage = LocalStorage();
  await storage.initialize();
  _markProgress('prepare:local_storage_initialize:done');
  _markProgress('prepare:local_storage_clear:start');
  await storage.clearAll();
  _markProgress('prepare:local_storage_clear:done');
  _markProgress('prepare:demo_services_reset:start');
  call_demo.DemoCallService().reset();
  call_demo.DemoMatchingService().cancelMatching();
  call_demo.DemoSOSService().cancelSOS();
  _markProgress('prepare:demo_services_reset:done');
}

void _markProgress(String stage) {
  final resultDir = Directory('eval/results')..createSync(recursive: true);
  final timestamp = DateTime.now().toIso8601String();
  File(
    '${resultDir.path}/eval_progress.log',
  ).writeAsStringSync('$timestamp $stage\n', mode: FileMode.append);
}

void _resetProgress() {
  final resultDir = Directory('eval/results')..createSync(recursive: true);
  File('${resultDir.path}/eval_progress.log').writeAsStringSync('');
}

List<EvalSample> _loadSamples(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
  final dataset = path.contains('emergency') ? 'emergency' : 'intent';
  return [
    for (final item in raw)
      EvalSample.fromJson(Map<String, dynamic>.from(item as Map), dataset),
  ];
}

Future<PredictionRow> _predictSample(
  EvalSample sample,
  AgentServiceFacade facade,
) async {
  final result = await facade.processInput(
    text: sample.text,
    imagePath: sample.imagePath,
    inputType: sample.imagePath == null ? 'text' : 'mixed',
  );
  return PredictionRow(sample: sample, result: result);
}

List<String> _orderedLabels(List<PredictionRow> rows) {
  final labels = <String>{
    for (final intent in DemoAiIntent.values) intent.wireName,
    for (final row in rows) row.predIntent,
    for (final row in rows) row.sample.goldIntent,
  }.toList();
  labels.sort();
  return labels;
}

Map<String, ClassMetric> _classMetrics(
  List<PredictionRow> rows,
  List<String> labels,
) {
  final out = <String, ClassMetric>{};
  for (final label in labels) {
    final tp = rows
        .where(
          (row) => row.sample.goldIntent == label && row.predIntent == label,
        )
        .length;
    final fp = rows
        .where(
          (row) => row.sample.goldIntent != label && row.predIntent == label,
        )
        .length;
    final fn = rows
        .where(
          (row) => row.sample.goldIntent == label && row.predIntent != label,
        )
        .length;
    final support = rows.where((row) => row.sample.goldIntent == label).length;
    out[label] = ClassMetric(tp: tp, fp: fp, fn: fn, support: support);
  }
  return out;
}

Map<String, Map<String, int>> _confusionMatrix(
  List<PredictionRow> rows,
  List<String> labels,
) {
  final matrix = {
    for (final gold in labels) gold: {for (final pred in labels) pred: 0},
  };
  for (final row in rows) {
    matrix[row.sample.goldIntent]![row.predIntent] =
        (matrix[row.sample.goldIntent]![row.predIntent] ?? 0) + 1;
  }
  return matrix;
}

double _accuracy(List<PredictionRow> rows, bool Function(PredictionRow) ok) {
  if (rows.isEmpty) return 0;
  return rows.where(ok).length / rows.length;
}

EmergencyStats _emergencyStats(List<PredictionRow> rows) {
  var tp = 0;
  var fn = 0;
  var fp = 0;
  var tn = 0;
  for (final row in rows) {
    final goldEmergency = row.sample.goldUrgency == 'emergency';
    final predEmergency =
        row.predUrgency == 'emergency' ||
        row.predNextAction == 'trigger_sos' ||
        row.predIntent == 'emergency';
    if (goldEmergency && predEmergency) tp++;
    if (goldEmergency && !predEmergency) fn++;
    if (!goldEmergency && predEmergency) fp++;
    if (!goldEmergency && !predEmergency) tn++;
  }
  return EmergencyStats(tp: tp, fn: fn, fp: fp, tn: tn);
}

Future<List<LatencyRow>> _runNonWidgetLatencyBenchmarks() async {
  final rows = <LatencyRow>[];
  _markProgress('latency:ai_response:start');
  rows.add(await _measureAIResponse());
  _markProgress('latency:ai_response:done');
  _markProgress('latency:top5_matching:start');
  rows.add(await _measureTop5Matching());
  _markProgress('latency:top5_matching:done');
  _markProgress('latency:demo_call:start');
  rows.add(await _measureDemoCallEstablish());
  _markProgress('latency:demo_call:done');
  _markProgress('latency:sos:start');
  rows.add(await _measureSosCancellationWindow());
  _markProgress('latency:sos:done');
  return rows;
}

Future<LatencyRow> _measureFirstScreen(WidgetTester tester) async {
  final samples = <double>[];
  for (var i = 0; i < 20; i++) {
    SharedPreferences.setMockInitialValues({});
    final sw = Stopwatch()..start();
    await app_entry.initializeCompetitionDemoApp();
    await tester.pumpWidget(app_entry.buildLinkLabApp());
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('让帮助真实发生\n连接每一次需要').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('让帮助真实发生\n连接每一次需要'), findsOneWidget);
    sw.stop();
    samples.add(sw.elapsedMicroseconds / 1000.0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
  return LatencyRow(
    metric: '首屏可见响应',
    mode: 'DemoMode widget-test',
    samples: samples,
    note: '包含 initializeCompetitionDemoApp + pumpWidget 到首页主文案可见；非线上冷启动。',
  );
}

Future<LatencyRow> _measureAIResponse() async {
  await _prepareEvalEnvironment();
  final facade = AgentServiceFacade();
  final samples = <double>[];
  for (var i = 0; i < 20; i++) {
    final sw = Stopwatch()..start();
    final result = await facade.processInput(text: '帮我读药品盒说明书');
    sw.stop();
    expect(result.success, isTrue);
    samples.add(sw.elapsedMicroseconds / 1000.0);
  }
  return LatencyRow(
    metric: 'AI 完整响应',
    mode: 'DemoMode local deterministic response',
    samples: samples,
    note: '走 AgentServiceFacade -> DemoAIService；含生产模拟延迟，不是真实 LLM 时延。',
  );
}

Future<LatencyRow> _measureTop5Matching() async {
  await _prepareEvalEnvironment();
  final engine = DemoMatchingEngineService();
  final pool = _volunteerPool50();
  final request = const DemoMatchRequest(
    requestId: 'eval_match_001',
    queryText: '我在医院大厅需要去取药窗口',
    requestType: 'navigation',
    urgencyLevel: 'normal',
  );
  final samples = <double>[];
  for (var i = 0; i < 20; i++) {
    final sw = Stopwatch()..start();
    final response = await engine.matchTopVolunteers(
      request,
      volunteerPool: pool,
    );
    sw.stop();
    expect(response.usesTopFive, isTrue);
    expect(response.results.length, min(5, pool.length));
    samples.add(sw.elapsedMicroseconds / 1000.0);
  }
  return LatencyRow(
    metric: '50 人候选 Top5 匹配耗时',
    mode: 'DemoMode production matching engine',
    samples: samples,
    note:
        '直接调用 DemoMatchingEngineService.matchTopVolunteers, volunteerPool=50。',
  );
}

Future<LatencyRow> _measureDemoCallEstablish() async {
  await _prepareEvalEnvironment();
  final service = call_demo.DemoCallService();
  final samples = <double>[];
  for (var i = 0; i < 20; i++) {
    service.reset();
    final sw = Stopwatch()..start();
    await service.startCall();
    sw.stop();
    expect(service.state, call_demo.DemoCallState.connected);
    samples.add(sw.elapsedMicroseconds / 1000.0);
    await service.hangUp();
  }
  return LatencyRow(
    metric: 'Demo Call 建立',
    mode: 'DemoMode production state machine',
    samples: samples,
    note: 'DemoCallService.startCall 固定包含 1s connecting + 2s ringing。',
  );
}

Future<LatencyRow> _measureSosCancellationWindow() async {
  await _prepareEvalEnvironment();
  final service = call_demo.DemoSOSService();
  final samples = <double>[];
  for (var i = 0; i < 20; i++) {
    service.cancelSOS();
    final sw = Stopwatch()..start();
    final future = service.triggerSOS();
    while (!service.isActive) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    sw.stop();
    samples.add(sw.elapsedMicroseconds / 1000.0);
    service.cancelSOS();
    await future;
  }
  return LatencyRow(
    metric: 'SOS 触发到撤销窗口',
    mode: 'DemoMode production state machine',
    samples: samples,
    note: '测量 DemoSOSService.triggerSOS 调用后 isActive=true；撤销窗口 UI 文案在页面层展示。',
  );
}

List<match_model.DemoVolunteer> _volunteerPool50() {
  const skillSets = [
    [demoSkillHospitalGuide, demoSkillMedicationHelp],
    [demoSkillVisualAssistance, demoSkillGeneralDirections],
    [demoSkillHearingCommunication, demoSkillDeliveryCommunication],
    [demoSkillElderlyCompanion, demoSkillGeneralDirections],
    [demoSkillEmergencyCompanion, demoSkillVisualAssistance],
  ];
  return [
    for (var i = 0; i < 50; i++)
      match_model.DemoVolunteer(
        id: 'eval_volunteer_${i.toString().padLeft(3, '0')}',
        nickname: '评测志愿者$i',
        avatarLabel: '志',
        distanceMeters: 100 + (i * 87) % 4800,
        skills: skillSets[i % skillSets.length],
        reputationScore: 0.72 + ((i % 20) / 100.0),
        isOnline: true,
        helpCount: 5 + (i * 7) % 120,
        estimatedResponseSeconds: 6 + (i * 3) % 40,
        preferredScenarios: const ['评测'],
        languageTags: const ['普通话'],
      ),
  ];
}

void _writeCsv(File file, List<List<String>> rows) {
  file.parent.createSync(recursive: true);
  final content = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  file.writeAsStringSync('$content\n');
}

String _csvCell(String value) {
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

String _pct(double value) => '${(value * 100).toStringAsFixed(2)}%';

LlmStatus _llmStatus() {
  final hasKey = APIConfig.isZhipuConfigured;
  final enabled = FeatureFlags.enableRealAI;
  if (enabled && hasKey) {
    return const LlmStatus(
      title: 'LLM 对照未自动运行',
      detail:
          '当前 runner 固定生成 DemoMode 规则基线。检测到真实 AI 可能可用，但为避免和规则基线混跑，需单独新增 real_ai runner。',
    );
  }
  return LlmStatus(
    title: 'LLM 对照未运行',
    detail:
        '缺少可用凭据或未显式开启真实 AI。FeatureFlags.enableRealAI=$enabled, APIConfig.isZhipuConfigured=$hasKey。',
  );
}

String _architectureMarkdown(List<EvalSample> samples) {
  final b = StringBuffer();
  b.writeln('# LinkAble AI Inference 架构勘察');
  b.writeln();
  b.writeln('生成时间:${DateTime.now().toIso8601String()}');
  b.writeln();
  b.writeln('## 真实入口');
  b.writeln();
  b.writeln(
    '- 规则意图入口:`DemoAIService.resolveIntent(String input, {String? imagePath, List<Map<String,String>>? history}) -> DemoAiIntent`。',
  );
  b.writeln(
    '- 规则综合处理入口:`DemoAIService.process(String input, {String? imagePath, List<Map<String,String>>? history}) -> Future<AIResult>`。',
  );
  b.writeln(
    '- 统一生产 facade:`AgentServiceFacade.processInput({String? text, String? imagePath, String inputType = "text"}) -> Future<AgentResult>`。本评测使用该入口输出 intent/urgency/next_action。',
  );
  b.writeln(
    '- 匹配入口:`DemoMatchingEngineService.matchTopVolunteers(DemoMatchRequest request, {List<DemoVolunteer>? volunteerPool}) -> Future<DemoMatchResponse>`。',
  );
  b.writeln();
  b.writeln('## 意图类别枚举');
  b.writeln();
  for (final intent in DemoAiIntent.values) {
    b.writeln('- `${intent.wireName}`:${intent.label}');
  }
  b.writeln();
  b.writeln('## urgency 与 next_action');
  b.writeln();
  b.writeln(
    '- urgency 实际输出来自 `AgentResult.urgency`: `normal`, `elevated`, `emergency`。',
  );
  b.writeln(
    '- next_action 实际输出来自 `AgentResult.nextAction`: `answer`, `ask_followup`, `match_volunteer`, `trigger_sos`, 错误时可能为 `show_fallback`。',
  );
  b.writeln(
    '- 映射规则:紧急 -> `trigger_sos`; 需要人工/nextStatus=matching -> `match_volunteer`; confidence < 0.65 -> `ask_followup`; 其他 -> `answer`。',
  );
  b.writeln();
  b.writeln('## 紧急关键词表');
  b.writeln();
  b.writeln('- DemoAIService 内置:`救命`, `晕倒`, `摔倒`, `胸口痛`, `迷路了`, `我很害怕`, `紧急`。');
  b.writeln(
    '- DemoDataLoader 资源表:`救命`, `着火了`, `有人抢劫`, `心脏病`, `流血不止`, `摔倒了`, `找不到路`, `迷路`, `头晕`, `不舒服`, `快来人`, `紧急求助`, `SOS` 等。',
  );
  b.writeln();
  b.writeln('## 匹配评分函数');
  b.writeln();
  b.writeln('- 真实 Demo Top5 评分函数:`DemoMatchingEngineService._scoreVolunteer`。');
  b.writeln(
    '- 权重:availability 0.30, distance 0.25, skill 0.20, trust 0.15, reputation 0.10。',
  );
  b.writeln(
    '- 排序 tie-break:score 降序 -> distance 升序 -> reputation 降序 -> estimatedResponseSeconds 升序 -> volunteer id。',
  );
  b.writeln();
  b.writeln('## 测试调用方法');
  b.writeln();
  b.writeln('```bash');
  b.writeln('cd /Users/insistgang/Downloads/cpicp/LinkLab/linklab');
  b.writeln('flutter test eval/test/eval_runner_test.dart');
  b.writeln('```');
  b.writeln();
  b.writeln('## 每条 gold 标注依据');
  b.writeln();
  b.writeln(
    '| id | gold_intent | gold_urgency | gold_next_action | subset | 判定依据 |',
  );
  b.writeln('|---|---|---|---|---|---|');
  for (final sample in samples) {
    b.writeln(
      '| ${sample.id} | ${sample.goldIntent} | ${sample.goldUrgency} | ${sample.goldNextAction} | ${sample.subset} | ${_md(sample.note)} |',
    );
  }
  return b.toString();
}

String _reportMarkdown({
  required List<MetricRow> metricsRows,
  required Map<String, ClassMetric> classMetrics,
  required List<String> labels,
  required Map<String, Map<String, int>> confusion,
  required List<PredictionRow> intentPredictions,
  required List<PredictionRow> emergencyPredictions,
  required List<PredictionRow> misclassified,
  required List<LatencyRow> latencyRows,
  required LlmStatus llmStatus,
}) {
  final b = StringBuffer();
  b.writeln('# LinkAble AI Inference 评测报告');
  b.writeln();
  b.writeln('生成时间:${DateTime.now().toIso8601String()}');
  b.writeln();
  b.writeln('## 结论摘要');
  b.writeln();
  b.writeln(
    '本次评测只测不调,所有分类结果来自 `AgentServiceFacade.processInput()` 与其后方生产规则/Demo fallback 路径。当前运行模式为 DemoMode,真实 LLM 对照未运行。',
  );
  b.writeln();
  b.writeln('## 架构事实摘要');
  b.writeln();
  b.writeln(
    '- 统一生产入口: `AgentServiceFacade.processInput({String? text, String? imagePath, String inputType = "text"}) -> Future<AgentResult>`。',
  );
  b.writeln(
    '- 规则意图入口: `DemoAIService.resolveIntent(String input, {String? imagePath, List<Map<String,String>>? history}) -> DemoAiIntent`。',
  );
  b.writeln(
    '- 规则综合处理入口: `DemoAIService.process(String input, {String? imagePath, List<Map<String,String>>? history}) -> Future<AIResult>`。',
  );
  b.writeln('- 实际意图枚举共 ${classMetrics.length} 类: ${labels.join(', ')}。');
  b.writeln(
    '- 实际 `urgency` 输出: `normal`, `elevated`, `emergency`; 实际 `next_action` 输出包含 `answer`, `ask_followup`, `match_volunteer`, `trigger_sos`, 错误时可能为 `show_fallback`。',
  );
  b.writeln(
    '- 志愿者 Top5 匹配入口: `DemoMatchingEngineService.matchTopVolunteers(...)`; 权重为 availability 0.30, distance 0.25, skill 0.20, trust 0.15, reputation 0.10。',
  );
  b.writeln('- 更完整的入口、关键词表、匹配权重和每条 gold 判定依据见 `eval/results/ARCHITECTURE.md`。');
  b.writeln();
  final easyIntentCount = intentPredictions
      .where((row) => row.sample.subset == 'easy')
      .length;
  final hardIntentCount = intentPredictions
      .where((row) => row.sample.subset == 'hard')
      .length;
  final emergencyPositiveCount = emergencyPredictions
      .where((row) => row.sample.goldUrgency == 'emergency')
      .length;
  final emergencyNegativeCount =
      emergencyPredictions.length - emergencyPositiveCount;
  b.writeln('## 测试集设计与防循环说明');
  b.writeln();
  b.writeln(
    '- 意图集: `eval/datasets/intent_samples.json`, 共 ${intentPredictions.length} 条, 覆盖真实 ${classMetrics.length} 个 `DemoAiIntent` 类, 每类 10 条。',
  );
  b.writeln(
    '- 意图 easy/hard 分布: easy $easyIntentCount 条, hard $hardIntentCount 条; 每类 hard 至少 4 条。',
  );
  b.writeln(
    '- 紧急集: `eval/datasets/emergency_samples.json`, 共 ${emergencyPredictions.length} 条, 其中真实紧急 $emergencyPositiveCount 条, 非紧急难负例 $emergencyNegativeCount 条。',
  );
  b.writeln(
    '- 防“自己考自己”: hard 样本刻意使用真实口吻、改写和隐含表达, 不照抄代码关键词; easy 样本保留直接表达, 用于形成 easy/hard 对照。',
  );
  b.writeln('- 所有预测均调用生产 facade, 没有在评测脚本中重写关键词规则或另造分类器。');
  b.writeln('- 本环境缺少 `openpyxl/xlsxwriter` 等 xlsx 写入库, 指标按用户允许的 CSV 形式输出。');
  b.writeln();
  b.writeln('## 指标总表');
  b.writeln();
  b.writeln('| 指标 | 目标 | 实测 | 备注 |');
  b.writeln('|---|---|---|---|');
  for (final row in metricsRows) {
    b.writeln(
      '| ${_md(row.metric)} | ${_md(row.target)} | ${_md(row.actual)} | ${_md(row.note)} |',
    );
  }
  b.writeln();
  b.writeln('## 各类 precision / recall');
  b.writeln();
  b.writeln('| class | precision | recall | tp | fp | fn | support |');
  b.writeln('|---|---:|---:|---:|---:|---:|---:|');
  for (final entry in classMetrics.entries) {
    final m = entry.value;
    b.writeln(
      '| ${entry.key} | ${m.precision.toStringAsFixed(3)} | ${m.recall.toStringAsFixed(3)} | ${m.tp} | ${m.fp} | ${m.fn} | ${m.support} |',
    );
  }
  b.writeln();
  b.writeln('## 混淆矩阵文件');
  b.writeln();
  b.writeln('- `eval/results/confusion_matrix.csv`');
  b.writeln('- 标签顺序:${labels.join(', ')}');
  b.writeln();
  b.writeln('## 时延说明');
  b.writeln();
  for (final row in latencyRows) {
    b.writeln(
      '- ${row.metric}: median=${row.medianMs.toStringAsFixed(2)}ms, p95=${row.p95Ms.toStringAsFixed(2)}ms。${row.note}',
    );
  }
  b.writeln();
  b.writeln('## LLM 对照');
  b.writeln();
  b.writeln('- ${llmStatus.title}:${llmStatus.detail}');
  b.writeln();
  b.writeln('## 错分样本与 limitation');
  b.writeln();
  b.writeln('完整错分清单见 `eval/results/misclassified.csv`。前 20 条如下:');
  b.writeln();
  b.writeln('| id | text | gold | pred | gold_action | pred_action | note |');
  b.writeln('|---|---|---|---|---|---|---|');
  for (final row in misclassified.take(20)) {
    b.writeln(
      '| ${row.sample.id} | ${_md(row.sample.text)} | ${row.sample.goldIntent}/${row.sample.goldUrgency} | ${row.predIntent}/${row.predUrgency} | ${row.sample.goldNextAction} | ${row.predNextAction} | ${_md(row.sample.note)} |',
    );
  }
  b.writeln();
  b.writeln(
    '主要限制:规则引擎对 hard 子集的改写/隐含表达天然更弱;物体识别等图片类任务依赖图片路径和视觉适配层;DemoMode AI 响应时延包含模拟延迟,不代表真实大模型服务耗时。',
  );
  b.writeln();
  b.writeln('## 工程证据材料');
  b.writeln();
  b.writeln(
    '- `eval/results/flutter_analyze.txt`: `flutter analyze` 输出文件。当前已知仅剩 1 个既有 info: `lib/services/demo_call_service.dart:358 use_null_aware_elements`。',
  );
  b.writeln(
    '- `eval/results/flutter_test.txt`: 全量 `flutter test` 输出文件。最近一次通过时结尾为 `All tests passed!`。',
  );
  b.writeln(
    '- `eval/results/flutter_build_apk.txt`: `flutter build apk --release` 输出文件。若本环境构建失败, 以该日志和 `apk_build.txt` 中的原因记录为准。',
  );
  b.writeln(
    '- `eval/results/apk_build.txt`: 记录现有 APK 的路径、mtime、sha256, 并明确标注它不是本轮构建命令产物。',
  );
  b.writeln();
  b.writeln('## 一条命令复现');
  b.writeln();
  b.writeln('```bash');
  b.writeln('cd /Users/insistgang/Downloads/cpicp/LinkLab/linklab');
  b.writeln('flutter test eval/test/eval_runner_test.dart');
  b.writeln('```');
  return b.toString();
}

String _md(String value) =>
    value.replaceAll('|', '\\|').replaceAll('\n', '<br>');

class EvalSample {
  const EvalSample({
    required this.id,
    required this.text,
    required this.goldIntent,
    required this.goldUrgency,
    required this.goldNextAction,
    required this.subset,
    required this.note,
    required this.dataset,
    this.imagePath,
  });

  final String id;
  final String text;
  final String goldIntent;
  final String goldUrgency;
  final String goldNextAction;
  final String subset;
  final String note;
  final String dataset;
  final String? imagePath;

  factory EvalSample.fromJson(Map<String, dynamic> json, String dataset) {
    return EvalSample(
      id: json['id'] as String,
      text: json['text'] as String,
      goldIntent: json['gold_intent'] as String,
      goldUrgency: json['gold_urgency'] as String,
      goldNextAction: json['gold_next_action'] as String,
      subset: json['subset'] as String,
      note: json['note'] as String,
      dataset: dataset,
      imagePath: json['image_path'] as String?,
    );
  }
}

class PredictionRow {
  PredictionRow({required this.sample, required this.result});

  final EvalSample sample;
  final AgentResult result;

  String get predIntent => result.intent;
  String get predUrgency => result.urgency;
  String get predNextAction => result.nextAction;
  bool get success => result.success;
  double get confidence => result.confidence;
}

class ClassMetric {
  const ClassMetric({
    required this.tp,
    required this.fp,
    required this.fn,
    required this.support,
  });

  final int tp;
  final int fp;
  final int fn;
  final int support;

  double get precision => tp + fp == 0 ? 0 : tp / (tp + fp);
  double get recall => tp + fn == 0 ? 0 : tp / (tp + fn);
}

class EmergencyStats {
  const EmergencyStats({
    required this.tp,
    required this.fn,
    required this.fp,
    required this.tn,
  });

  final int tp;
  final int fn;
  final int fp;
  final int tn;

  int get positiveTotal => tp + fn;
  int get negativeTotal => fp + tn;
  double get recall => positiveTotal == 0 ? 0 : tp / positiveTotal;
  double get falsePositiveRate => negativeTotal == 0 ? 0 : fp / negativeTotal;
}

class MetricRow {
  const MetricRow(this.metric, this.target, this.actual, this.note);

  final String metric;
  final String target;
  final String actual;
  final String note;
}

class LatencyRow {
  const LatencyRow({
    required this.metric,
    required this.mode,
    required this.samples,
    required this.note,
  });

  final String metric;
  final String mode;
  final List<double> samples;
  final String note;

  double get medianMs => _percentile(samples, 0.50);
  double get p95Ms => _percentile(samples, 0.95);
  double get minMs => samples.reduce(min);
  double get maxMs => samples.reduce(max);
}

double _percentile(List<double> values, double p) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * p).ceil().clamp(0, sorted.length - 1);
  return sorted[index];
}

class LlmStatus {
  const LlmStatus({required this.title, required this.detail});

  final String title;
  final String detail;
}
