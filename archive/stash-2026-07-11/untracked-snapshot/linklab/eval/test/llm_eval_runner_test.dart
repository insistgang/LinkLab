@Tags(['eval', 'llm'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'package:linklab/config/api_config.dart';
import 'package:linklab/config/app_config.dart';
import 'package:linklab/models/demo_ai_intent.dart';

const _resultDirPath = 'eval/results';
const _llmModel = 'glm-4-flash';
const _preflightSeed = 20260627;
const _requestTimeout = Duration(seconds: 30);

final _intentLabels = [
  for (final intent in DemoAiIntent.values) intent.wireName,
];
const _urgencyLabels = ['normal', 'elevated', 'emergency'];
const _nextActionLabels = [
  'answer',
  'ask_followup',
  'match_volunteer',
  'trigger_sos',
  'show_fallback',
];

void main() {
  test(
    'LinkAble real LLM inference comparison runner',
    () async {
      Logger.level = Level.off;

      final resultDir = Directory(_resultDirPath)..createSync(recursive: true);
      final intentSamples = _loadSamples('eval/datasets/intent_samples.json');
      final emergencySamples = _loadSamples(
        'eval/datasets/emergency_samples.json',
      );
      final allSamples = [...intentSamples, ...emergencySamples];

      _writeObjectIdentifyArchitectureSection(resultDir);

      final config = await _configureRealAI();
      if (!config.isReady) {
        final reason = config.failureReason;
        _writeFailureOutputs(
          resultDir: resultDir,
          intentSamples: intentSamples,
          emergencySamples: emergencySamples,
          reason: reason,
          stage: 'config',
        );
        fail(reason);
      }

      final classifier = _ZhipuEvalClassifier(http.Client());
      try {
        final selfCheckSample = intentSamples.firstWhere(
          (sample) => sample.id == 'intent_ocr_text_001',
        );
        final selfCheck = await classifier.classify(selfCheckSample);
        _writeCsv(File('${resultDir.path}/llm_self_check.csv'), [
          _rawPredictionHeader,
          _rawPredictionRow(selfCheck),
        ]);
        if (!selfCheck.success) {
          final reason =
              'LLM 连通性自检失败: ${selfCheck.errorType}; ${selfCheck.reason}';
          _writeFailureOutputs(
            resultDir: resultDir,
            intentSamples: intentSamples,
            emergencySamples: emergencySamples,
            reason: reason,
            stage: 'self_check',
            rows: [selfCheck],
          );
          fail(reason);
        }

        final preflightSamples = _selectPreflightSamples(allSamples);
        final preflightRows = <LlmPredictionRow>[];
        for (final sample in preflightSamples) {
          preflightRows.add(await classifier.classify(sample));
        }
        _writeCsv(File('${resultDir.path}/llm_preflight_raw_predictions.csv'), [
          _rawPredictionHeader,
          for (final row in preflightRows) _rawPredictionRow(row),
        ]);
        final failedPreflight = preflightRows.where((row) => !row.success);
        if (failedPreflight.isNotEmpty) {
          final reason =
              'LLM 小样本预跑失败: ${failedPreflight.length}/${preflightRows.length} 条无法解析或请求失败';
          _writeFailureOutputs(
            resultDir: resultDir,
            intentSamples: intentSamples,
            emergencySamples: emergencySamples,
            reason: reason,
            stage: 'preflight',
            rows: preflightRows,
          );
          fail(reason);
        }

        final predictions = <LlmPredictionRow>[];
        for (final sample in allSamples) {
          predictions.add(await classifier.classify(sample));
        }

        final intentPredictions = predictions
            .where((row) => row.sample.dataset == 'intent')
            .toList();
        final emergencyPredictions = predictions
            .where((row) => row.sample.dataset == 'emergency')
            .toList();
        final llmSummary = _summaryFor(predictions);
        final ruleRows = _loadRulePredictions();
        final ruleSummary = _summaryFor(ruleRows);
        final ruleVsLlmRows = _ruleVsLlmRows(ruleSummary, llmSummary);
        final emergencyGapRows = _emergencyGapRows(ruleRows, predictions);

        _writeLlmMetricFiles(
          resultDir: resultDir,
          predictions: predictions,
          intentPredictions: intentPredictions,
          emergencyPredictions: emergencyPredictions,
          summary: llmSummary,
          ruleVsLlmRows: ruleVsLlmRows,
          emergencyGapRows: emergencyGapRows,
        );
        _updateReport(
          resultDir: resultDir,
          status: 'completed',
          detail: '真实 LLM 对照已完成，模型 $_llmModel，样本 ${predictions.length} 条。',
          ruleVsLlmRows: ruleVsLlmRows,
          summary: llmSummary,
          emergencyGapRows: emergencyGapRows,
        );

        expect(predictions, hasLength(160));
        expect(
          File('${resultDir.path}/llm_raw_predictions.csv').readAsLinesSync(),
          hasLength(161),
        );
        expect(
          File(
            '${resultDir.path}/llm_intent_metrics_by_class.csv',
          ).readAsLinesSync(),
          hasLength(13),
        );
        expect(
          File('${resultDir.path}/llm_confusion_matrix.csv').readAsLinesSync(),
          hasLength(13),
        );
        expect(
          emergencyGapRows.length,
          greaterThanOrEqualTo(10),
          reason: '规则基线此前有 10 条真实紧急漏报，gap 文件应覆盖这些样本。',
        );
      } finally {
        classifier.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 60)),
  );
}

Future<_ConfigCheck> _configureRealAI() async {
  var dotEnvLoaded = false;
  try {
    await dotenv.load(fileName: '.env');
    dotEnvLoaded = true;
  } catch (_) {
    dotEnvLoaded = false;
  }
  final env = <String, String>{...dotenv.env, ...Platform.environment};

  APIConfig.reset();
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
  AppConfig.configureFromEnvironment(
    env,
    preferRealMode: false,
    enablePresenterSessionOnFallback: false,
    enableRealAIFromEnvironment: true,
  );

  final problems = <String>[];
  if (!FeatureFlags.enableRealAI) {
    problems.add(
      'FeatureFlags.enableRealAI=false; LINKABLE_ENABLE_REAL_AI=${env['LINKABLE_ENABLE_REAL_AI'] ?? '<missing>'}',
    );
  }
  if (!APIConfig.isZhipuConfigured) {
    problems.add('APIConfig.isZhipuConfigured=false; ZHIPU_API_KEY 未配置或为空');
  }
  return _ConfigCheck(dotEnvLoaded: dotEnvLoaded, problems: problems);
}

String? _envValue(Map<String, String> env, String key) {
  final value = env[key]?.trim();
  if (value == null || value.isEmpty || value.startsWith('YOUR_')) {
    return null;
  }
  return value;
}

List<EvalSample> _loadSamples(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
  final dataset = path.contains('emergency') ? 'emergency' : 'intent';
  return [
    for (final item in raw)
      EvalSample.fromJson(Map<String, dynamic>.from(item as Map), dataset),
  ];
}

List<EvalSample> _selectPreflightSamples(List<EvalSample> samples) {
  final selected = <String, EvalSample>{};
  void addWhere(bool Function(EvalSample sample) predicate) {
    final sample = samples.firstWhere(predicate);
    selected[sample.id] = sample;
  }

  addWhere((sample) => sample.goldIntent == 'object_identify');
  addWhere(
    (sample) =>
        sample.dataset == 'emergency' &&
        sample.goldUrgency == 'emergency' &&
        sample.subset == 'hard',
  );
  addWhere(
    (sample) =>
        sample.dataset == 'emergency' &&
        sample.goldUrgency != 'emergency' &&
        sample.subset == 'hard',
  );
  addWhere((sample) => sample.dataset == 'intent' && sample.subset == 'hard');

  final shuffled = [...samples]..shuffle(Random(_preflightSeed));
  for (final sample in shuffled) {
    selected[sample.id] = sample;
    final values = selected.values.toList();
    final hardCount = values.where((sample) => sample.subset == 'hard').length;
    final emergencyPosCount = values
        .where(
          (sample) =>
              sample.dataset == 'emergency' &&
              sample.goldUrgency == 'emergency',
        )
        .length;
    final hasObject = values.any(
      (sample) => sample.goldIntent == 'object_identify',
    );
    if (values.length >= 15 &&
        hardCount >= 5 &&
        emergencyPosCount >= 3 &&
        hasObject) {
      break;
    }
  }

  return selected.values.take(15).toList();
}

class _ZhipuEvalClassifier {
  _ZhipuEvalClassifier(this._client);

  final http.Client _client;

  Future<LlmPredictionRow> classify(EvalSample sample) async {
    final sw = Stopwatch()..start();
    int? statusCode;
    String rawOutput = '';
    try {
      final response = await _client
          .post(
            Uri.parse('${APIConfig.zhipuBaseUrl}/chat/completions'),
            headers: {
              HttpHeaders.authorizationHeader:
                  'Bearer ${APIConfig.zhipuApiKey}',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode({
              'model': _llmModel,
              'temperature': 0,
              'top_p': 0.1,
              'max_tokens': 300,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': _userPrompt(sample)},
              ],
            }),
          )
          .timeout(_requestTimeout);
      sw.stop();
      statusCode = response.statusCode;
      rawOutput = response.body;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return LlmPredictionRow.failure(
          sample: sample,
          latencyMs: sw.elapsedMicroseconds / 1000.0,
          httpStatus: statusCode,
          errorType: 'http_${response.statusCode}',
          rawOutput: rawOutput,
          reason: _truncate(response.body, 300),
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      final message = choices?.isNotEmpty == true
          ? (choices!.first as Map<String, dynamic>)['message']
                as Map<String, dynamic>?
          : null;
      rawOutput = (message?['content'] as String?)?.trim() ?? response.body;
      final parsed = _parseClassifierJson(rawOutput);
      if (parsed == null) {
        return LlmPredictionRow.failure(
          sample: sample,
          latencyMs: sw.elapsedMicroseconds / 1000.0,
          httpStatus: statusCode,
          errorType: 'parse_error',
          rawOutput: rawOutput,
          reason: '模型返回非 JSON 或 JSON 缺字段',
        );
      }
      return LlmPredictionRow.success(
        sample: sample,
        predIntent: parsed.intent,
        predUrgency: parsed.urgency,
        predNextAction: parsed.nextAction,
        confidence: parsed.confidence,
        latencyMs: sw.elapsedMicroseconds / 1000.0,
        httpStatus: statusCode,
        rawOutput: rawOutput,
        reason: parsed.reason,
      );
    } on TimeoutException catch (error) {
      sw.stop();
      return LlmPredictionRow.failure(
        sample: sample,
        latencyMs: sw.elapsedMicroseconds / 1000.0,
        httpStatus: statusCode,
        errorType: 'timeout',
        rawOutput: rawOutput,
        reason: error.toString(),
      );
    } catch (error) {
      sw.stop();
      return LlmPredictionRow.failure(
        sample: sample,
        latencyMs: sw.elapsedMicroseconds / 1000.0,
        httpStatus: statusCode,
        errorType: 'exception',
        rawOutput: rawOutput,
        reason: error.toString(),
      );
    }
  }

  void close() => _client.close();
}

const _systemPrompt = '''
你是 LinkAble 竞赛评测专用的意图分类器，只做分类，不回答用户问题。
必须只输出一个 JSON 对象，不要 Markdown，不要解释性前后缀。

JSON schema:
{
  "intent": "one of allowed_intents",
  "urgency": "normal|elevated|emergency",
  "next_action": "answer|ask_followup|match_volunteer|trigger_sos|show_fallback",
  "confidence": 0.0-1.0,
  "reason": "简短中文理由"
}

分类准则:
- intent 只能从用户消息给出的 allowed_intents 中选择。
- urgency 只能为 normal/elevated/emergency。
- next_action 只能从用户消息给出的 allowed_next_actions 中选择。
- 紧急人身/医疗/火灾/被困/被跟踪/无法脱险等风险应 urgency=emergency 且 next_action=trigger_sos。
- 导航、环境安全、明确需要真人兜底时 next_action=match_volunteer。
- 模糊但不紧急时 next_action=ask_followup。
- 有 image_path 的样本只代表用户上传了图片；不要推断图片内容，只根据用户文本和 has_image 判断意图。
''';

String _userPrompt(EvalSample sample) {
  return jsonEncode({
    'sample_id': sample.id,
    'dataset': sample.dataset,
    'text': sample.text,
    'has_image': sample.imagePath != null,
    'allowed_intents': _intentLabels,
    'allowed_urgencies': _urgencyLabels,
    'allowed_next_actions': _nextActionLabels,
  });
}

_ParsedClassifierOutput? _parseClassifierJson(String raw) {
  var content = raw.trim();
  if (content.startsWith('```')) {
    content = content.replaceFirst(RegExp(r'^```json\s*', multiLine: true), '');
    content = content.replaceFirst(RegExp(r'^```\s*', multiLine: true), '');
    content = content.replaceFirst(RegExp(r'\s*```$'), '');
  }
  final start = content.indexOf('{');
  final end = content.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  content = content.substring(start, end + 1);

  try {
    final map = jsonDecode(content) as Map<String, dynamic>;
    final intent = (map['intent'] as String?)?.trim();
    final urgency = (map['urgency'] as String?)?.trim();
    final nextAction = (map['next_action'] as String?)?.trim();
    final confidence = _asDouble(map['confidence']);
    final reason = (map['reason'] as String?)?.trim() ?? '';
    if (!_intentLabels.contains(intent) ||
        !_urgencyLabels.contains(urgency) ||
        !_nextActionLabels.contains(nextAction) ||
        confidence == null) {
      return null;
    }
    return _ParsedClassifierOutput(
      intent: intent!,
      urgency: urgency!,
      nextAction: nextAction!,
      confidence: confidence.clamp(0, 1).toDouble(),
      reason: reason,
    );
  } catch (_) {
    return null;
  }
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

void _writeFailureOutputs({
  required Directory resultDir,
  required List<EvalSample> intentSamples,
  required List<EvalSample> emergencySamples,
  required String reason,
  required String stage,
  List<LlmPredictionRow> rows = const [],
}) {
  final ruleRows = _loadRulePredictions();
  final ruleSummary = _summaryFor(ruleRows);
  final emptySummary = EvalSummary.empty();
  final ruleVsLlmRows = _ruleVsLlmRows(
    ruleSummary,
    emptySummary,
    llmUnavailableReason: reason,
  );
  final emergencyGapRows = _emergencyGapRows(
    ruleRows,
    rows,
    notRunReason: reason,
  );

  File(
    '${resultDir.path}/llm_eval_status.txt',
  ).writeAsStringSync('真实 LLM 对照未完成\nstage=$stage\nreason=$reason\n');
  _writeCsv(File('${resultDir.path}/llm_raw_predictions.csv'), [
    _rawPredictionHeader,
    for (final row in rows) _rawPredictionRow(row),
  ]);
  _writeCsv(File('${resultDir.path}/llm_inference_metrics.csv'), [
    ['指标', '目标', '实测', '备注'],
    ['真实 LLM 对照状态', '必须真实运行', '未运行', reason],
  ]);
  _writeCsv(File('${resultDir.path}/llm_intent_metrics_by_class.csv'), [
    ['class', 'precision', 'recall', 'tp', 'fp', 'fn', 'support'],
    for (final label in _intentLabels)
      [
        label,
        'not_run',
        'not_run',
        '0',
        '0',
        '0',
        '${intentSamples.where((sample) => sample.goldIntent == label).length}',
      ],
  ]);
  _writeCsv(File('${resultDir.path}/llm_confusion_matrix.csv'), [
    ['gold\\pred', ..._intentLabels, 'note'],
    for (final label in _intentLabels)
      [label, for (final _ in _intentLabels) '', reason],
  ]);
  _writeCsv(File('${resultDir.path}/llm_latency_results.csv'), [
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
    ['LLM 单样本真实调用', 'real Zhipu $_llmModel', '0', '', '', '', '', reason],
  ]);
  _writeCsv(File('${resultDir.path}/rule_vs_llm.csv'), [
    ['metric', 'rule_baseline', 'llm', 'delta', 'note'],
    for (final row in ruleVsLlmRows)
      [row.metric, row.ruleBaseline, row.llm, row.delta, row.note],
  ]);
  _writeCsv(File('${resultDir.path}/emergency_gap_analysis.csv'), [
    [
      'id',
      'text',
      'rule_pred_intent',
      'rule_pred_next_action',
      'llm_pred_intent',
      'llm_pred_next_action',
      'llm_caught',
      'reason',
    ],
    for (final row in emergencyGapRows)
      [
        row.id,
        row.text,
        row.rulePredIntent,
        row.rulePredNextAction,
        row.llmPredIntent,
        row.llmPredNextAction,
        row.llmCaught,
        row.reason,
      ],
  ]);
  _updateReport(
    resultDir: resultDir,
    status: 'failed',
    detail: reason,
    ruleVsLlmRows: ruleVsLlmRows,
    summary: emptySummary,
    emergencyGapRows: emergencyGapRows,
  );
}

void _writeLlmMetricFiles({
  required Directory resultDir,
  required List<LlmPredictionRow> predictions,
  required List<LlmPredictionRow> intentPredictions,
  required List<LlmPredictionRow> emergencyPredictions,
  required EvalSummary summary,
  required List<ComparisonRow> ruleVsLlmRows,
  required List<EmergencyGapRow> emergencyGapRows,
}) {
  final classMetrics = _classMetrics(intentPredictions);
  final predLabels = [
    ..._intentLabels,
    if (intentPredictions.any((row) => !_intentLabels.contains(row.predIntent)))
      '__error__',
  ];
  final confusion = _confusionMatrix(intentPredictions, predLabels);
  final latency = LatencyRow(
    metric: 'LLM 单样本真实调用',
    mode: 'real Zhipu $_llmModel',
    samples: [for (final row in predictions) row.latencyMs],
    note: '逐条调用智谱 Chat Completions；含网络往返、模型生成与 JSON 解析前耗时。',
  );

  _writeCsv(File('${resultDir.path}/llm_inference_metrics.csv'), [
    ['指标', '目标', '实测', '备注'],
    [
      'LLM 意图识别总准确率',
      '越高越好；按真实 DemoAiIntent 12 类',
      _pct(summary.intentAccuracy),
      'n=${intentPredictions.length}, real $_llmModel',
    ],
    ['LLM 意图识别 easy 子集准确率', '越高越好', _pct(summary.easyAccuracy), '直接/显式表达样本'],
    ['LLM 意图识别 hard 子集准确率', '越高越好', _pct(summary.hardAccuracy), '改写/隐含表达样本'],
    ['LLM next_action 正确率', '越高越好', _pct(summary.actionAccuracy), '覆盖意图集+紧急集'],
    [
      'LLM 紧急召回率',
      '目标高召回；不得漏 SOS',
      _pct(summary.emergencyStats.recall),
      '${summary.emergencyStats.tp}/${summary.emergencyStats.positiveTotal} 真实紧急被命中',
    ],
    [
      'LLM 紧急误报率',
      '越低越好',
      _pct(summary.emergencyStats.falsePositiveRate),
      '${summary.emergencyStats.fp}/${summary.emergencyStats.negativeTotal} 非紧急被误判紧急',
    ],
    [
      'LLM 调用成功率',
      '越高越好',
      _pct(summary.successRate),
      '${summary.successCount}/${predictions.length} 条 HTTP+JSON+枚举解析成功',
    ],
  ]);
  _writeCsv(File('${resultDir.path}/llm_intent_metrics_by_class.csv'), [
    ['class', 'precision', 'recall', 'tp', 'fp', 'fn', 'support'],
    for (final label in _intentLabels)
      [
        label,
        classMetrics[label]!.precision.toStringAsFixed(6),
        classMetrics[label]!.recall.toStringAsFixed(6),
        '${classMetrics[label]!.tp}',
        '${classMetrics[label]!.fp}',
        '${classMetrics[label]!.fn}',
        '${classMetrics[label]!.support}',
      ],
  ]);
  _writeCsv(File('${resultDir.path}/llm_confusion_matrix.csv'), [
    ['gold\\pred', ...predLabels],
    for (final gold in _intentLabels)
      [gold, for (final pred in predLabels) '${confusion[gold]?[pred] ?? 0}'],
  ]);
  _writeCsv(File('${resultDir.path}/llm_raw_predictions.csv'), [
    _rawPredictionHeader,
    for (final row in predictions) _rawPredictionRow(row),
  ]);
  _writeCsv(File('${resultDir.path}/llm_latency_results.csv'), [
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
    [
      latency.metric,
      latency.mode,
      '${latency.samples.length}',
      latency.medianMs.toStringAsFixed(6),
      latency.p95Ms.toStringAsFixed(6),
      latency.minMs.toStringAsFixed(6),
      latency.maxMs.toStringAsFixed(6),
      latency.note,
    ],
  ]);
  _writeCsv(File('${resultDir.path}/rule_vs_llm.csv'), [
    ['metric', 'rule_baseline', 'llm', 'delta', 'note'],
    for (final row in ruleVsLlmRows)
      [row.metric, row.ruleBaseline, row.llm, row.delta, row.note],
  ]);
  _writeCsv(File('${resultDir.path}/emergency_gap_analysis.csv'), [
    [
      'id',
      'text',
      'rule_pred_intent',
      'rule_pred_next_action',
      'llm_pred_intent',
      'llm_pred_next_action',
      'llm_caught',
      'reason',
    ],
    for (final row in emergencyGapRows)
      [
        row.id,
        row.text,
        row.rulePredIntent,
        row.rulePredNextAction,
        row.llmPredIntent,
        row.llmPredNextAction,
        row.llmCaught,
        row.reason,
      ],
  ]);
  File('${resultDir.path}/llm_eval_status.txt').writeAsStringSync(
    '真实 LLM 对照已完成\nmodel=$_llmModel\nsamples=${predictions.length}\n',
  );
}

List<RulePredictionRow> _loadRulePredictions() {
  final file = File('eval/results/raw_predictions.csv');
  if (!file.existsSync()) return const [];
  final rows = _readCsv(file);
  if (rows.length <= 1) return const [];
  final header = rows.first;
  return [
    for (final row in rows.skip(1))
      RulePredictionRow.fromCsv({
        for (var i = 0; i < header.length && i < row.length; i++)
          header[i]: row[i],
      }),
  ];
}

EvalSummary _summaryFor(List<PredictionLike> rows) {
  if (rows.isEmpty) return EvalSummary.empty();
  final intentRows = rows
      .where((row) => row.sample.dataset == 'intent')
      .toList();
  final emergencyRows = rows
      .where((row) => row.sample.dataset == 'emergency')
      .toList();
  final easyRows = intentRows
      .where((row) => row.sample.subset == 'easy')
      .toList();
  final hardRows = intentRows
      .where((row) => row.sample.subset == 'hard')
      .toList();
  final successCount = rows.where((row) => row.success).length;
  return EvalSummary(
    intentAccuracy: _accuracy(
      intentRows,
      (row) => row.predIntent == row.sample.goldIntent,
    ),
    easyAccuracy: _accuracy(
      easyRows,
      (row) => row.predIntent == row.sample.goldIntent,
    ),
    hardAccuracy: _accuracy(
      hardRows,
      (row) => row.predIntent == row.sample.goldIntent,
    ),
    actionAccuracy: _accuracy(
      rows,
      (row) => row.predNextAction == row.sample.goldNextAction,
    ),
    emergencyStats: _emergencyStats(emergencyRows),
    successCount: successCount,
    totalCount: rows.length,
    latencySamples: [for (final row in rows) row.latencyMs],
  );
}

double _accuracy(List<PredictionLike> rows, bool Function(PredictionLike) ok) {
  if (rows.isEmpty) return 0;
  return rows.where(ok).length / rows.length;
}

Map<String, ClassMetric> _classMetrics(List<PredictionLike> rows) {
  final out = <String, ClassMetric>{};
  for (final label in _intentLabels) {
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
  List<PredictionLike> rows,
  List<String> predLabels,
) {
  final matrix = {
    for (final gold in _intentLabels)
      gold: {for (final pred in predLabels) pred: 0},
  };
  for (final row in rows) {
    if (!_intentLabels.contains(row.sample.goldIntent)) continue;
    final pred = predLabels.contains(row.predIntent)
        ? row.predIntent
        : '__error__';
    matrix[row.sample.goldIntent]![pred] =
        (matrix[row.sample.goldIntent]![pred] ?? 0) + 1;
  }
  return matrix;
}

EmergencyStats _emergencyStats(List<PredictionLike> rows) {
  var tp = 0;
  var fn = 0;
  var fp = 0;
  var tn = 0;
  for (final row in rows) {
    final goldEmergency = row.sample.goldUrgency == 'emergency';
    final predEmergency = _isEmergencyPrediction(row);
    if (goldEmergency && predEmergency) tp++;
    if (goldEmergency && !predEmergency) fn++;
    if (!goldEmergency && predEmergency) fp++;
    if (!goldEmergency && !predEmergency) tn++;
  }
  return EmergencyStats(tp: tp, fn: fn, fp: fp, tn: tn);
}

bool _isEmergencyPrediction(PredictionLike row) {
  return row.predUrgency == 'emergency' ||
      row.predNextAction == 'trigger_sos' ||
      row.predIntent == 'emergency';
}

List<ComparisonRow> _ruleVsLlmRows(
  EvalSummary rule,
  EvalSummary llm, {
  String? llmUnavailableReason,
}) {
  ComparisonRow pctRow(
    String metric,
    double ruleValue,
    double llmValue,
    String note,
  ) {
    return ComparisonRow(
      metric: metric,
      ruleBaseline: _pct(ruleValue),
      llm: llmUnavailableReason == null ? _pct(llmValue) : 'not_run',
      delta: llmUnavailableReason == null
          ? _signedPct(llmValue - ruleValue)
          : 'n/a',
      note: llmUnavailableReason ?? note,
    );
  }

  final rows = <ComparisonRow>[
    pctRow(
      'intent_accuracy',
      rule.intentAccuracy,
      llm.intentAccuracy,
      '意图集总准确率',
    ),
    pctRow(
      'easy_intent_accuracy',
      rule.easyAccuracy,
      llm.easyAccuracy,
      '意图 easy 子集',
    ),
    pctRow(
      'hard_intent_accuracy',
      rule.hardAccuracy,
      llm.hardAccuracy,
      '意图 hard 子集，最能体现改写/隐含表达差距',
    ),
    pctRow(
      'next_action_accuracy',
      rule.actionAccuracy,
      llm.actionAccuracy,
      '意图集+紧急集',
    ),
    pctRow(
      'emergency_recall',
      rule.emergencyStats.recall,
      llm.emergencyStats.recall,
      '真实紧急样本命中率',
    ),
    pctRow(
      'emergency_false_positive_rate',
      rule.emergencyStats.falsePositiveRate,
      llm.emergencyStats.falsePositiveRate,
      '真实非紧急被误判紧急比例',
    ),
  ];
  if (llmUnavailableReason == null) {
    final latency = LatencyRow(
      metric: 'LLM 单样本真实调用',
      mode: 'real Zhipu $_llmModel',
      samples: llm.latencySamples,
      note: '',
    );
    rows.addAll([
      ComparisonRow(
        metric: 'llm_success_rate',
        ruleBaseline: 'n/a',
        llm: _pct(llm.successRate),
        delta: 'n/a',
        note: '${llm.successCount}/${llm.totalCount} 条成功解析',
      ),
      ComparisonRow(
        metric: 'llm_latency_median_ms',
        ruleBaseline: 'n/a',
        llm: latency.medianMs.toStringAsFixed(2),
        delta: 'n/a',
        note: '真实 LLM HTTP 调用中位耗时',
      ),
      ComparisonRow(
        metric: 'llm_latency_p95_ms',
        ruleBaseline: 'n/a',
        llm: latency.p95Ms.toStringAsFixed(2),
        delta: 'n/a',
        note: '真实 LLM HTTP 调用 p95 耗时',
      ),
    ]);
  }
  return rows;
}

List<EmergencyGapRow> _emergencyGapRows(
  List<RulePredictionRow> ruleRows,
  List<PredictionLike> llmRows, {
  String? notRunReason,
}) {
  final llmById = {for (final row in llmRows) row.sample.id: row};
  final missedByRule = ruleRows.where(
    (row) =>
        row.sample.dataset == 'emergency' &&
        row.sample.goldUrgency == 'emergency' &&
        !_isEmergencyPrediction(row),
  );
  return [
    for (final ruleRow in missedByRule)
      _gapRow(ruleRow, llmById[ruleRow.sample.id], notRunReason: notRunReason),
  ];
}

EmergencyGapRow _gapRow(
  RulePredictionRow ruleRow,
  PredictionLike? llmRow, {
  String? notRunReason,
}) {
  if (llmRow == null) {
    return EmergencyGapRow(
      id: ruleRow.sample.id,
      text: ruleRow.sample.text,
      rulePredIntent: ruleRow.predIntent,
      rulePredNextAction: ruleRow.predNextAction,
      llmPredIntent: 'not_run',
      llmPredNextAction: 'not_run',
      llmCaught: 'not_run',
      reason: notRunReason ?? 'LLM 未运行或无该样本输出',
    );
  }
  final caught = _isEmergencyPrediction(llmRow);
  return EmergencyGapRow(
    id: ruleRow.sample.id,
    text: ruleRow.sample.text,
    rulePredIntent: ruleRow.predIntent,
    rulePredNextAction: ruleRow.predNextAction,
    llmPredIntent: llmRow.predIntent,
    llmPredNextAction: llmRow.predNextAction,
    llmCaught: '$caught',
    reason: caught
        ? 'LLM 将该隐式/组合风险判为紧急。'
        : '两者均漏报；可能原因是文本未出现显式 SOS 词，需要补充组合风险/人身威胁判断。',
  );
}

void _writeObjectIdentifyArchitectureSection(Directory resultDir) {
  final file = File('${resultDir.path}/ARCHITECTURE.md');
  final current = file.existsSync() ? file.readAsStringSync() : '';
  final section =
      '''
## object_identify 路由诊断

生成时间:${DateTime.now().toIso8601String()}

结论: `object_identify` 规则基线 0% 不是评测脚本漏传图片导致的，而是 DemoMode 生产规则缺少图片物体识别分支。本阶段只诊断，不修改生产逻辑。

证据:
- `eval/test/eval_runner_test.dart:353-357` 调用 `AgentServiceFacade.processInput(...)` 时已经传入 `imagePath: sample.imagePath`，且 `inputType` 在有图时为 `mixed`。
- `lib/services/demo/demo_ai_service.dart:274-285` 的 `imagePath != null` 分支只判断 color / ocr / environment，未判断 object / product / 商品 / 物体语义，最后默认返回 `DemoAiIntent.sceneDescription`。
- `lib/services/facades/agent_service_facade.dart:68-89` 在 `FeatureFlags.enableRealAI=false` 时优先走 `_processDemoInput(...)`，因此规则基线先进入 `DemoAIService`。
- `lib/services/facades/agent_service_facade.dart:235-258` 的 image fallback 层有 object keyword 分支，但 DemoMode 规则基线未触达该分支。

建议修法: 后续若进入规则改进阶段，可在 `DemoAIService._detectDemoIntent()` 的图片分支中加入 object/product/商品/物体/东西/用品/工具等语义判断，或调整 facade 的图片 fallback 路由顺序。不要在本轮 LLM 对照阶段为测试集逐条硬编码。
''';
  file.writeAsStringSync(
    _replaceOrAppendSection(current, '## object_identify 路由诊断', section),
  );
}

void _updateReport({
  required Directory resultDir,
  required String status,
  required String detail,
  required List<ComparisonRow> ruleVsLlmRows,
  required EvalSummary summary,
  required List<EmergencyGapRow> emergencyGapRows,
}) {
  final file = File('${resultDir.path}/REPORT.md');
  var report = file.existsSync()
      ? file.readAsStringSync()
      : '# LinkAble AI Inference 评测报告\n';
  report = _replaceOrAppendSection(report, '## 结论摘要', '''
## 结论摘要

本报告保留上一轮 DemoMode 规则基线结论，并新增本轮真实 LLM 对照 runner。规则基线仍为可离线复现的确定性结果；真实 LLM 对照状态为 `$status`，原因/摘要为：${_md(_trimTrailingPunctuation(detail))}。所有 LLM 数字只在真实 `$_llmModel` 调用完成后写入，缺配置或请求失败时不估算、不回退 Demo。
''');
  report = _replaceOrAppendSection(report, '## LLM 对照', '''
## LLM 对照

- 本轮新增 eval-only 真实 LLM runner: `flutter test eval/test/llm_eval_runner_test.dart`。
- 状态: $status。$detail
- 真实 LLM 路径不使用 `AgentServiceFacade._chatWithLLM()` 的回答型结果作为分类器；本 runner 调用智谱 `$_llmModel` Chat Completions，并强制输出 12 类同口径 JSON。
''');
  report = _replaceOrAppendSection(
    report,
    '## 真实 LLM 对照（本轮增量）',
    _llmReportSection(
      status: status,
      detail: detail,
      ruleVsLlmRows: ruleVsLlmRows,
      summary: summary,
      emergencyGapRows: emergencyGapRows,
    ),
  );
  file.writeAsStringSync(report);
}

String _llmReportSection({
  required String status,
  required String detail,
  required List<ComparisonRow> ruleVsLlmRows,
  required EvalSummary summary,
  required List<EmergencyGapRow> emergencyGapRows,
}) {
  final b = StringBuffer();
  b.writeln('## 真实 LLM 对照（本轮增量）');
  b.writeln();
  b.writeln('生成时间:${DateTime.now().toIso8601String()}');
  b.writeln();
  b.writeln('- 状态: $status。${_md(detail)}');
  b.writeln('- 模型路径: eval-only runner -> 智谱 Chat Completions `$_llmModel`。');
  b.writeln(
    '- 样本: 沿用 `eval/datasets/intent_samples.json` 120 条与 `eval/datasets/emergency_samples.json` 40 条，未改动 gold 标注。',
  );
  b.writeln(
    '- 图片样本: prompt 只传 `has_image=true` 与用户文本，不发送 dummy 图片字节，避免把占位图当真实视觉证据。',
  );
  b.writeln();
  if (status == 'completed') {
    b.writeln('### LLM 指标摘要');
    b.writeln();
    b.writeln('- 意图总准确率: ${_pct(summary.intentAccuracy)}');
    b.writeln(
      '- easy / hard: ${_pct(summary.easyAccuracy)} / ${_pct(summary.hardAccuracy)}',
    );
    b.writeln('- 紧急召回率: ${_pct(summary.emergencyStats.recall)}');
    b.writeln('- 紧急误报率: ${_pct(summary.emergencyStats.falsePositiveRate)}');
    b.writeln('- next_action 正确率: ${_pct(summary.actionAccuracy)}');
    b.writeln(
      '- 成功解析率: ${_pct(summary.successRate)} (${summary.successCount}/${summary.totalCount})',
    );
    b.writeln();
  } else {
    b.writeln('### LLM 指标摘要');
    b.writeln();
    b.writeln(
      '真实 LLM 未完成运行，因此不填准确率、召回率或时延数字。失败原因已写入 `eval/results/llm_eval_status.txt`。',
    );
    b.writeln();
  }
  b.writeln('### 规则 vs LLM 对照');
  b.writeln();
  b.writeln('| metric | 规则基线 | LLM | 差值 | note |');
  b.writeln('|---|---:|---:|---:|---|');
  for (final row in ruleVsLlmRows) {
    b.writeln(
      '| ${_md(row.metric)} | ${_md(row.ruleBaseline)} | ${_md(row.llm)} | ${_md(row.delta)} | ${_md(row.note)} |',
    );
  }
  b.writeln();
  b.writeln(
    '完整文件: `eval/results/rule_vs_llm.csv`、`eval/results/llm_raw_predictions.csv`、`eval/results/llm_inference_metrics.csv`。',
  );
  b.writeln();
  b.writeln('### object_identify 诊断结论');
  b.writeln();
  b.writeln(
    '`object_identify` 0% 是生产规则 limitation: 评测脚本已传 `imagePath` 与 `inputType=mixed`，但 `DemoAIService._detectDemoIntent()` 图片分支没有 object 判断，默认落到 `scene_description`。详见 `eval/results/ARCHITECTURE.md` 的同名小节。',
  );
  b.writeln();
  b.writeln('### 紧急召回 gap 分析');
  b.writeln();
  b.writeln(
    '规则基线真实紧急漏报样本数: ${emergencyGapRows.length}。逐条分析见 `eval/results/emergency_gap_analysis.csv`。',
  );
  if (emergencyGapRows.isNotEmpty) {
    final bothMissed = emergencyGapRows
        .where((row) => row.llmCaught == 'false')
        .length;
    final caught = emergencyGapRows
        .where((row) => row.llmCaught == 'true')
        .length;
    final notRun = emergencyGapRows
        .where((row) => row.llmCaught == 'not_run')
        .length;
    b.writeln(
      '- LLM 接住: $caught 条；两者都漏: $bothMissed 条；LLM 未运行/无输出: $notRun 条。',
    );
  }
  b.writeln();
  b.writeln(
    '后续改进方向: 规则层可补组合风险特征（夜间+迷路+低电量、被跟随、被困、呼吸困难、他人倒地无回应），并把 LLM 作为 hard 子集和低置信样本的补充分流层；任何规则改动都需要用同一测试集前后复测。',
  );
  b.writeln();
  b.writeln('### 复现命令');
  b.writeln();
  b.writeln('```bash');
  b.writeln('cd /Users/insistgang/Downloads/cpicp/LinkLab/linklab');
  b.writeln('flutter test eval/test/llm_eval_runner_test.dart');
  b.writeln('# 规则基线刷新: flutter test eval/test/eval_runner_test.dart');
  b.writeln('```');
  return b.toString();
}

String _replaceOrAppendSection(String markdown, String title, String section) {
  final start = markdown.indexOf(title);
  if (start < 0) {
    return '${markdown.trimRight()}\n\n${section.trimRight()}\n';
  }
  final next = markdown.indexOf('\n## ', start + title.length);
  if (next < 0) {
    return '${markdown.substring(0, start).trimRight()}\n\n${section.trimRight()}\n';
  }
  return '${markdown.substring(0, start).trimRight()}\n\n${section.trimRight()}\n\n${markdown.substring(next + 1).trimLeft()}';
}

const _rawPredictionHeader = [
  'id',
  'dataset',
  'subset',
  'text',
  'has_image',
  'gold_intent',
  'pred_intent',
  'gold_urgency',
  'pred_urgency',
  'gold_next_action',
  'pred_next_action',
  'success',
  'confidence',
  'latency_ms',
  'http_status',
  'error_type',
  'raw_output',
  'reason',
  'note',
];

List<String> _rawPredictionRow(LlmPredictionRow row) {
  return [
    row.sample.id,
    row.sample.dataset,
    row.sample.subset,
    row.sample.text,
    '${row.sample.imagePath != null}',
    row.sample.goldIntent,
    row.predIntent,
    row.sample.goldUrgency,
    row.predUrgency,
    row.sample.goldNextAction,
    row.predNextAction,
    '${row.success}',
    row.confidence.toStringAsFixed(6),
    row.latencyMs.toStringAsFixed(6),
    row.httpStatus?.toString() ?? '',
    row.errorType,
    row.rawOutput,
    row.reason,
    row.sample.note,
  ];
}

void _writeCsv(File file, List<List<String>> rows) {
  file.parent.createSync(recursive: true);
  final content = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  file.writeAsStringSync('$content\n');
}

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

List<List<String>> _readCsv(File file) {
  return [
    for (final line in file.readAsLinesSync())
      if (line.isNotEmpty) _parseCsvLine(line),
  ];
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      cells.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  cells.add(buffer.toString());
  return cells;
}

String _pct(double value) => '${(value * 100).toStringAsFixed(2)}%';

String _signedPct(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${(value * 100).toStringAsFixed(2)}pp';
}

String _md(String value) =>
    value.replaceAll('|', '\\|').replaceAll('\n', '<br>');

String _truncate(String value, int limit) {
  if (value.length <= limit) return value;
  return '${value.substring(0, limit)}...';
}

String _trimTrailingPunctuation(String value) {
  return value.replaceFirst(RegExp(r'[。.!！]+$'), '');
}

double _percentile(List<double> values, double p) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * p).ceil().clamp(0, sorted.length - 1);
  return sorted[index];
}

abstract class PredictionLike {
  EvalSample get sample;
  String get predIntent;
  String get predUrgency;
  String get predNextAction;
  bool get success;
  double get latencyMs;
}

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

class RulePredictionRow implements PredictionLike {
  RulePredictionRow({
    required this.sample,
    required this.predIntent,
    required this.predUrgency,
    required this.predNextAction,
    required this.success,
    required this.confidence,
  });

  factory RulePredictionRow.fromCsv(Map<String, String> row) {
    return RulePredictionRow(
      sample: EvalSample(
        id: row['id'] ?? '',
        dataset: row['dataset'] ?? '',
        subset: row['subset'] ?? '',
        text: row['text'] ?? '',
        goldIntent: row['gold_intent'] ?? '',
        goldUrgency: row['gold_urgency'] ?? '',
        goldNextAction: row['gold_next_action'] ?? '',
        note: '',
      ),
      predIntent: row['pred_intent'] ?? '',
      predUrgency: row['pred_urgency'] ?? '',
      predNextAction: row['pred_next_action'] ?? '',
      success: (row['success'] ?? '').toLowerCase() == 'true',
      confidence: double.tryParse(row['confidence'] ?? '') ?? 0,
    );
  }

  @override
  final EvalSample sample;
  @override
  final String predIntent;
  @override
  final String predUrgency;
  @override
  final String predNextAction;
  @override
  final bool success;
  final double confidence;
  @override
  double get latencyMs => 0;
}

class LlmPredictionRow implements PredictionLike {
  const LlmPredictionRow._({
    required this.sample,
    required this.predIntent,
    required this.predUrgency,
    required this.predNextAction,
    required this.success,
    required this.confidence,
    required this.latencyMs,
    required this.httpStatus,
    required this.errorType,
    required this.rawOutput,
    required this.reason,
  });

  factory LlmPredictionRow.success({
    required EvalSample sample,
    required String predIntent,
    required String predUrgency,
    required String predNextAction,
    required double confidence,
    required double latencyMs,
    required int? httpStatus,
    required String rawOutput,
    required String reason,
  }) {
    return LlmPredictionRow._(
      sample: sample,
      predIntent: predIntent,
      predUrgency: predUrgency,
      predNextAction: predNextAction,
      success: true,
      confidence: confidence,
      latencyMs: latencyMs,
      httpStatus: httpStatus,
      errorType: '',
      rawOutput: rawOutput,
      reason: reason,
    );
  }

  factory LlmPredictionRow.failure({
    required EvalSample sample,
    required double latencyMs,
    required int? httpStatus,
    required String errorType,
    required String rawOutput,
    required String reason,
  }) {
    return LlmPredictionRow._(
      sample: sample,
      predIntent: '__error__',
      predUrgency: 'unknown',
      predNextAction: 'show_fallback',
      success: false,
      confidence: 0,
      latencyMs: latencyMs,
      httpStatus: httpStatus,
      errorType: errorType,
      rawOutput: rawOutput,
      reason: reason,
    );
  }

  @override
  final EvalSample sample;
  @override
  final String predIntent;
  @override
  final String predUrgency;
  @override
  final String predNextAction;
  @override
  final bool success;
  final double confidence;
  @override
  final double latencyMs;
  final int? httpStatus;
  final String errorType;
  final String rawOutput;
  final String reason;
}

class _ParsedClassifierOutput {
  const _ParsedClassifierOutput({
    required this.intent,
    required this.urgency,
    required this.nextAction,
    required this.confidence,
    required this.reason,
  });

  final String intent;
  final String urgency;
  final String nextAction;
  final double confidence;
  final String reason;
}

class _ConfigCheck {
  const _ConfigCheck({required this.dotEnvLoaded, required this.problems});

  final bool dotEnvLoaded;
  final List<String> problems;

  bool get isReady => problems.isEmpty;

  String get failureReason {
    final envText = dotEnvLoaded ? '.env 已加载' : '.env 未加载';
    return '$envText；${problems.join('；')}';
  }
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

class EvalSummary {
  const EvalSummary({
    required this.intentAccuracy,
    required this.easyAccuracy,
    required this.hardAccuracy,
    required this.actionAccuracy,
    required this.emergencyStats,
    required this.successCount,
    required this.totalCount,
    required this.latencySamples,
  });

  factory EvalSummary.empty() {
    return const EvalSummary(
      intentAccuracy: 0,
      easyAccuracy: 0,
      hardAccuracy: 0,
      actionAccuracy: 0,
      emergencyStats: EmergencyStats(tp: 0, fn: 0, fp: 0, tn: 0),
      successCount: 0,
      totalCount: 0,
      latencySamples: [],
    );
  }

  final double intentAccuracy;
  final double easyAccuracy;
  final double hardAccuracy;
  final double actionAccuracy;
  final EmergencyStats emergencyStats;
  final int successCount;
  final int totalCount;
  final List<double> latencySamples;

  double get successRate => totalCount == 0 ? 0 : successCount / totalCount;
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
  double get minMs => samples.isEmpty ? 0 : samples.reduce(min);
  double get maxMs => samples.isEmpty ? 0 : samples.reduce(max);
}

class ComparisonRow {
  const ComparisonRow({
    required this.metric,
    required this.ruleBaseline,
    required this.llm,
    required this.delta,
    required this.note,
  });

  final String metric;
  final String ruleBaseline;
  final String llm;
  final String delta;
  final String note;
}

class EmergencyGapRow {
  const EmergencyGapRow({
    required this.id,
    required this.text,
    required this.rulePredIntent,
    required this.rulePredNextAction,
    required this.llmPredIntent,
    required this.llmPredNextAction,
    required this.llmCaught,
    required this.reason,
  });

  final String id;
  final String text;
  final String rulePredIntent;
  final String rulePredNextAction;
  final String llmPredIntent;
  final String llmPredNextAction;
  final String llmCaught;
  final String reason;
}
