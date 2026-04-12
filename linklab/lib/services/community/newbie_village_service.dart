import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 新手村服务
class NewbieVillageService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 开始训练
  Future<NewbieTraining?> startTraining(String volunteerId) async {
    try {
      // 检查是否已有训练记录
      final existing = await _supabase
          .from('newbie_trainings')
          .select()
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用户已有训练记录');
        return NewbieTraining.fromJson(existing);
      }

      // 创建新的训练记录
      final response = await _supabase
          .from('newbie_trainings')
          .insert({
            'volunteer_id': volunteerId,
            'completed_scenarios': 0,
            'total_scenarios': 3,
            'is_graduated': false,
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      AppLogger.info('开始新手训练: $volunteerId');
      return NewbieTraining.fromJson(response);
    } catch (e) {
      AppLogger.error('开始训练失败', e);
      return null;
    }
  }

  /// 获取训练进度
  Future<NewbieTraining?> getTrainingProgress(String volunteerId) async {
    try {
      final response = await _supabase
          .from('newbie_trainings')
          .select()
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (response == null) return null;
      return NewbieTraining.fromJson(response);
    } catch (e) {
      AppLogger.error('获取训练进度失败', e);
      return null;
    }
  }

  /// 完成模拟场景
  Future<void> completeScenario(
    String volunteerId,
    String scenarioId, {
    int score = 100,
    String? feedback,
  }) async {
    try {
      // 记录场景完成
      await _supabase.from('completed_scenarios').insert({
        'volunteer_id': volunteerId,
        'scenario_id': scenarioId,
        'score': score,
        'feedback': feedback,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // 更新训练进度
      await _supabase.rpc('increment_completed_scenarios', params: {
        'volunteer_id': volunteerId,
      });

      // 检查是否毕业
      await checkGraduation(volunteerId);

      AppLogger.info('完成模拟场景: $scenarioId');
    } catch (e) {
      AppLogger.error('完成模拟场景失败', e);
      rethrow;
    }
  }

  /// 检查毕业状态
  Future<bool> checkGraduation(String volunteerId) async {
    try {
      final training = await getTrainingProgress(volunteerId);
      if (training == null) return false;

      // 检查是否已完成所有场景
      if (training.completedScenarios >= training.totalScenarios &&
          !training.isGraduated) {
        // 更新毕业状态
        await _supabase.from('newbie_trainings').update({
          'is_graduated': true,
          'graduated_at': DateTime.now().toIso8601String(),
        }).eq('volunteer_id', volunteerId);

        // 更新志愿者等级
        await _supabase.from('volunteer_profiles').update({
          'level': 2,
        }).eq('user_id', volunteerId);

        AppLogger.info('志愿者毕业: $volunteerId');
        return true;
      }

      return training.isGraduated;
    } catch (e) {
      AppLogger.error('检查毕业状态失败', e);
      return false;
    }
  }

  /// 分配导师
  Future<void> assignMentor(String newbieId, String mentorId) async {
    try {
      // 检查导师是否存在且是资深志愿者
      final mentor = await _supabase
          .from('volunteer_profiles')
          .select()
          .eq('user_id', mentorId)
          .single();

      if (mentor['level'] < 3) {
        throw Exception('导师必须是正式志愿者（等级3以上）');
      }

      // 获取导师信息
      final mentorUser = await _supabase
          .from('users')
          .select('name')
          .eq('id', mentorId)
          .single();

      // 更新训练记录
      await _supabase.from('newbie_trainings').update({
        'mentor_id': mentorId,
        'mentor_name': mentorUser['name'] ?? '导师',
      }).eq('volunteer_id', newbieId);

      AppLogger.info('分配导师成功: $mentorId -> $newbieId');
    } catch (e) {
      AppLogger.error('分配导师失败', e);
      rethrow;
    }
  }

  /// 获取可用导师列表
  Future<List<Map<String, dynamic>>> getAvailableMentors() async {
    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('*, users(name, avatar_url)')
          .gte('level', 3)
          .eq('is_verified', true)
          .order('level', ascending: false)
          .limit(20);

      return (response as List).map((json) {
        final userData = json['users'] as Map<String, dynamic>?;
        return {
          'id': json['user_id'],
          'name': userData?['name'] ?? '志愿者',
          'avatar': userData?['avatar_url'],
          'level': json['level'],
          'helpCount': json['total_help_count'] ?? 0,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('获取导师列表失败', e);
      return [];
    }
  }

  /// 获取所有模拟场景
  Future<List<TrainingScenario>> getAllScenarios() async {
    try {
      final response = await _supabase
          .from('training_scenarios')
          .select()
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => TrainingScenario.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取模拟场景失败', e);
      return [];
    }
  }

  /// 获取场景详情
  Future<TrainingScenario?> getScenarioDetail(String scenarioId) async {
    try {
      final response = await _supabase
          .from('training_scenarios')
          .select()
          .eq('id', scenarioId)
          .single();

      return TrainingScenario.fromJson(response);
    } catch (e) {
      AppLogger.error('获取场景详情失败', e);
      return null;
    }
  }

  /// 获取用户已完成的场景
  Future<List<String>> getCompletedScenarios(String volunteerId) async {
    try {
      final response = await _supabase
          .from('completed_scenarios')
          .select('scenario_id')
          .eq('volunteer_id', volunteerId);

      return (response as List)
          .map((json) => json['scenario_id'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('获取已完成场景失败', e);
      return [];
    }
  }

  /// 初始化预设场景
  Future<void> initializePresetScenarios() async {
    try {
      final presetScenarios = _getPresetScenarios();

      for (final scenario in presetScenarios) {
        // 检查是否已存在
        final existing = await _supabase
            .from('training_scenarios')
            .select()
            .eq('type', scenario['type'])
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('training_scenarios').insert(scenario);
        }
      }

      AppLogger.info('预设场景初始化完成');
    } catch (e) {
      AppLogger.error('初始化预设场景失败', e);
    }
  }

  /// 获取预设场景
  List<Map<String, dynamic>> _getPresetScenarios() {
    return [
      {
        'title': '药品识别场景',
        'description': '视障用户需要识别药品名称和用法用量。请指导用户使用OCR功能识别药品包装上的文字信息。',
        'type': ScenarioType.ocr,
        'image_url': 'assets/images/training/ocr_scenario.png',
        'hints': [
          '引导用户对准药品包装',
          '确保光线充足',
          '提醒用户核对药品名称',
          '帮助用户理解用法用量',
        ],
        'expected_actions': [
          '打开相机',
          '对准药品',
          '识别文字',
          '朗读结果',
        ],
        'sort_order': 1,
      },
      {
        'title': '场景描述场景',
        'description': '视障用户想了解周围环境。请详细描述场景中的关键信息，帮助用户建立空间认知。',
        'type': ScenarioType.sceneDescription,
        'image_url': 'assets/images/training/scene_scenario.png',
        'hints': [
          '描述整体环境',
          '指出重要地标',
          '说明方向和距离',
          '提醒潜在障碍',
        ],
        'expected_actions': [
          '观察环境',
          '描述场景',
          '指出关键信息',
          '提供导航建议',
        ],
        'sort_order': 2,
      },
      {
        'title': '导航指引场景',
        'description': '视障用户需要前往目的地。请提供清晰的导航指引，包括方向、距离和路标。',
        'type': ScenarioType.navigation,
        'image_url': 'assets/images/training/navigation_scenario.png',
        'hints': [
          '确认当前位置',
          '明确目的地',
          '分步骤指引',
          '确认用户理解',
        ],
        'expected_actions': [
          '定位当前位置',
          '规划路线',
          '逐步指引',
          '确认到达',
        ],
        'sort_order': 3,
      },
    ];
  }

  /// 提交训练反馈
  Future<void> submitFeedback(
    String volunteerId,
    String scenarioId, {
    required int rating,
    String? comment,
  }) async {
    try {
      await _supabase.from('training_feedback').insert({
        'volunteer_id': volunteerId,
        'scenario_id': scenarioId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('提交训练反馈成功');
    } catch (e) {
      AppLogger.error('提交训练反馈失败', e);
      rethrow;
    }
  }

  /// 获取训练统计
  Future<Map<String, dynamic>> getTrainingStats(String volunteerId) async {
    try {
      final training = await getTrainingProgress(volunteerId);
      final completedScenarios = await getCompletedScenarios(volunteerId);

      return {
        'totalScenarios': training?.totalScenarios ?? 3,
        'completedScenarios': completedScenarios.length,
        'progressPercentage':
            ((completedScenarios.length / (training?.totalScenarios ?? 3)) * 100)
                .round(),
        'isGraduated': training?.isGraduated ?? false,
        'mentorName': training?.mentorName,
      };
    } catch (e) {
      AppLogger.error('获取训练统计失败', e);
      return {
        'totalScenarios': 3,
        'completedScenarios': 0,
        'progressPercentage': 0,
        'isGraduated': false,
      };
    }
  }
}
