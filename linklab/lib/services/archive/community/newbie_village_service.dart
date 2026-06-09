import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 新手村服務
class NewbieVillageService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 開始訓練
  Future<NewbieTraining?> startTraining(String volunteerId) async {
    try {
      // 檢查是否已有訓練記錄
      final existing = await _supabase
          .from('newbie_trainings')
          .select()
          .eq('volunteer_id', volunteerId)
          .maybeSingle();

      if (existing != null) {
        AppLogger.info('用戶已有訓練記錄');
        return NewbieTraining.fromJson(existing);
      }

      // 創建新的訓練記錄
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

      AppLogger.info('開始新手訓練: $volunteerId');
      return NewbieTraining.fromJson(response);
    } catch (e) {
      AppLogger.error('開始訓練失敗', e);
      return null;
    }
  }

  /// 獲取訓練進度
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
      AppLogger.error('獲取訓練進度失敗', e);
      return null;
    }
  }

  /// 完成模擬場景
  Future<void> completeScenario(
    String volunteerId,
    String scenarioId, {
    int score = 100,
    String? feedback,
  }) async {
    try {
      // 記錄場景完成
      await _supabase.from('completed_scenarios').insert({
        'volunteer_id': volunteerId,
        'scenario_id': scenarioId,
        'score': score,
        'feedback': feedback,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // 更新訓練進度
      await _supabase.rpc('increment_completed_scenarios', params: {
        'volunteer_id': volunteerId,
      });

      // 檢查是否畢業
      await checkGraduation(volunteerId);

      AppLogger.info('完成模擬場景: $scenarioId');
    } catch (e) {
      AppLogger.error('完成模擬場景失敗', e);
      rethrow;
    }
  }

  /// 檢查畢業狀態
  Future<bool> checkGraduation(String volunteerId) async {
    try {
      final training = await getTrainingProgress(volunteerId);
      if (training == null) return false;

      // 檢查是否已完成所有場景
      if (training.completedScenarios >= training.totalScenarios &&
          !training.isGraduated) {
        // 更新畢業狀態
        await _supabase.from('newbie_trainings').update({
          'is_graduated': true,
          'graduated_at': DateTime.now().toIso8601String(),
        }).eq('volunteer_id', volunteerId);

        // 更新志願者等級
        await _supabase.from('volunteer_profiles').update({
          'level': 2,
        }).eq('user_id', volunteerId);

        AppLogger.info('志願者畢業: $volunteerId');
        return true;
      }

      return training.isGraduated;
    } catch (e) {
      AppLogger.error('檢查畢業狀態失敗', e);
      return false;
    }
  }

  /// 分配導師
  Future<void> assignMentor(String newbieId, String mentorId) async {
    try {
      // 檢查導師是否存在且是資深志願者
      final mentor = await _supabase
          .from('volunteer_profiles')
          .select()
          .eq('user_id', mentorId)
          .single();

      if (mentor['level'] < 3) {
        throw Exception('導師必須是正式志願者（等級3以上）');
      }

      // 獲取導師信息
      final mentorUser = await _supabase
          .from('users')
          .select('name')
          .eq('id', mentorId)
          .single();

      // 更新訓練記錄
      await _supabase.from('newbie_trainings').update({
        'mentor_id': mentorId,
        'mentor_name': mentorUser['name'] ?? '導師',
      }).eq('volunteer_id', newbieId);

      AppLogger.info('分配導師成功: $mentorId -> $newbieId');
    } catch (e) {
      AppLogger.error('分配導師失敗', e);
      rethrow;
    }
  }

  /// 獲取可用導師列表
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
          'name': userData?['name'] ?? '志願者',
          'avatar': userData?['avatar_url'],
          'level': json['level'],
          'helpCount': json['total_help_count'] ?? 0,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('獲取導師列表失敗', e);
      return [];
    }
  }

  /// 獲取所有模擬場景
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
      AppLogger.error('獲取模擬場景失敗', e);
      return [];
    }
  }

  /// 獲取場景詳情
  Future<TrainingScenario?> getScenarioDetail(String scenarioId) async {
    try {
      final response = await _supabase
          .from('training_scenarios')
          .select()
          .eq('id', scenarioId)
          .single();

      return TrainingScenario.fromJson(response);
    } catch (e) {
      AppLogger.error('獲取場景詳情失敗', e);
      return null;
    }
  }

  /// 獲取用戶已完成的場景
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
      AppLogger.error('獲取已完成場景失敗', e);
      return [];
    }
  }

  /// 初始化預設場景
  Future<void> initializePresetScenarios() async {
    try {
      final presetScenarios = _getPresetScenarios();

      for (final scenario in presetScenarios) {
        // 檢查是否已存在
        final existing = await _supabase
            .from('training_scenarios')
            .select()
            .eq('type', scenario['type'])
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('training_scenarios').insert(scenario);
        }
      }

      AppLogger.info('預設場景初始化完成');
    } catch (e) {
      AppLogger.error('初始化預設場景失敗', e);
    }
  }

  /// 獲取預設場景
  List<Map<String, dynamic>> _getPresetScenarios() {
    return [
      {
        'title': '藥品識別場景',
        'description': '視障用戶需要識別藥品名稱和用法用量。請指導用戶使用OCR功能識別藥品包裝上的文字信息。',
        'type': ScenarioType.ocr,
        'image_url': null,
        'hints': [
          '引導用戶對準藥品包裝',
          '確保光線充足',
          '提醒用戶覈對藥品名稱',
          '幫助用戶理解用法用量',
        ],
        'expected_actions': [
          '打開相機',
          '對準藥品',
          '識別文字',
          '朗讀結果',
        ],
        'sort_order': 1,
      },
      {
        'title': '場景描述場景',
        'description': '視障用戶想了解周圍環境。請詳細描述場景中的關鍵信息，幫助用戶建立空間認知。',
        'type': ScenarioType.sceneDescription,
        'image_url': null,
        'hints': [
          '描述整體環境',
          '指出重要地標',
          '說明方向和距離',
          '提醒潛在障礙',
        ],
        'expected_actions': [
          '觀察環境',
          '描述場景',
          '指出關鍵信息',
          '提供導航建議',
        ],
        'sort_order': 2,
      },
      {
        'title': '導航指引場景',
        'description': '視障用戶需要前往目的地。請提供清晰的導航指引，包括方向、距離和路標。',
        'type': ScenarioType.navigation,
        'image_url': null,
        'hints': [
          '確認當前位置',
          '明確目的地',
          '分步驟指引',
          '確認用戶理解',
        ],
        'expected_actions': [
          '定位當前位置',
          '規劃路線',
          '逐步指引',
          '確認到達',
        ],
        'sort_order': 3,
      },
    ];
  }

  /// 提交訓練反饋
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

      AppLogger.info('提交訓練反饋成功');
    } catch (e) {
      AppLogger.error('提交訓練反饋失敗', e);
      rethrow;
    }
  }

  /// 獲取訓練統計
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
      AppLogger.error('獲取訓練統計失敗', e);
      return {
        'totalScenarios': 3,
        'completedScenarios': 0,
        'progressPercentage': 0,
        'isGraduated': false,
      };
    }
  }
}
