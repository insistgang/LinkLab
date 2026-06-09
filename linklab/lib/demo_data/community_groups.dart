import '../models/community_group_model.dart';
import '../widgets/demo/linkable_icon.dart';

/// 社區小組Demo數據
class CommunityGroupsData {
  /// 獲取所有Demo小組
  static List<CommunityGroup> getAllGroups() {
    return [
      CommunityGroup(
        id: 'group_visual',
        name: '視障互助圈',
        description: '視障朋友交流日常生活經驗，分享出行技巧和輔助工具使用心得。',
        icon: LinkableIconName.visualImpairment,
        memberCount: 1286,
        category: CommunityGroupCategory.visualImpairment,
        lastActiveTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      CommunityGroup(
        id: 'group_hearing',
        name: '聽障交流圈',
        description: '聽障夥伴分享溝通技巧、助聽設備使用體驗，互相支持鼓勵。',
        icon: LinkableIconName.hearingImpairment,
        memberCount: 958,
        category: CommunityGroupCategory.hearingImpairment,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CommunityGroup(
        id: 'group_mobility',
        name: '輪椅出行圈',
        description: '輪椅使用者交流無障礙出行經驗，分享坡道、電梯等設施信息。',
        icon: LinkableIconName.mobilityImpairment,
        memberCount: 723,
        category: CommunityGroupCategory.mobilityImpairment,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CommunityGroup(
        id: 'group_elderly',
        name: '老年關愛圈',
        description: '老年人健康生活交流，分享養生知識和防騙技巧。',
        icon: LinkableIconName.elderly,
        memberCount: 2156,
        category: CommunityGroupCategory.elderlyCare,
        lastActiveTime: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      CommunityGroup(
        id: 'group_medicine',
        name: '藥品諮詢圈',
        description: '藥品使用經驗分享，用藥注意事項交流，互相提醒健康事項。',
        icon: LinkableIconName.medicineCheck,
        memberCount: 1567,
        category: CommunityGroupCategory.medicineConsult,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommunityGroup(
        id: 'group_hospital',
        name: '導診互助圈',
        description: '醫院就診經驗分享，掛號流程指引，陪診志願者招募。',
        icon: LinkableIconName.navigationGuide,
        memberCount: 892,
        category: CommunityGroupCategory.hospitalGuide,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  /// 根據ID獲取小組
  static CommunityGroup? getGroupById(String id) {
    try {
      return getAllGroups().firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 獲取小組討論列表
  static List<GroupDiscussion> getDiscussions(String groupId) {
    final now = DateTime.now();

    switch (groupId) {
      case 'group_visual':
        return [
          GroupDiscussion(
            id: 'disc_1',
            groupId: groupId,
            userName: '陽光行者',
            content: '今天用讀屏軟件成功在新超市購物了！分享一下經驗...',
            createdAt: now.subtract(const Duration(minutes: 30)),
            likeCount: 24,
            replyCount: 8,
          ),
          GroupDiscussion(
            id: 'disc_2',
            groupId: groupId,
            userName: '獨立生活家',
            content: '推薦一款很好用的盲文學習APP，界面簡潔易操作。',
            createdAt: now.subtract(const Duration(hours: 2)),
            likeCount: 18,
            replyCount: 5,
          ),
          GroupDiscussion(
            id: 'disc_3',
            groupId: groupId,
            userName: '探索者',
            content: '週末有誰想去公園散步？可以一起交流出行心得。',
            createdAt: now.subtract(const Duration(hours: 5)),
            likeCount: 12,
            replyCount: 15,
          ),
        ];

      case 'group_hearing':
        return [
          GroupDiscussion(
            id: 'disc_4',
            groupId: groupId,
            userName: '靜默舞者',
            content: '這款助聽器降噪效果很好，推薦給大家！',
            createdAt: now.subtract(const Duration(hours: 1)),
            likeCount: 32,
            replyCount: 12,
          ),
          GroupDiscussion(
            id: 'disc_5',
            groupId: groupId,
            userName: '手語達人',
            content: '本週六有手語角活動，歡迎新手參加！',
            createdAt: now.subtract(const Duration(hours: 4)),
            likeCount: 45,
            replyCount: 20,
          ),
        ];

      case 'group_mobility':
        return [
          GroupDiscussion(
            id: 'disc_6',
            groupId: groupId,
            userName: '輪椅行者',
            content: '分享一個無障礙地圖小程序，可以查看各地坡道信息。',
            createdAt: now.subtract(const Duration(hours: 3)),
            likeCount: 28,
            replyCount: 9,
          ),
          GroupDiscussion(
            id: 'disc_7',
            groupId: groupId,
            userName: '自由飛翔',
            content: '地鐵站的無障礙電梯位置彙總，持續更新中...',
            createdAt: now.subtract(const Duration(hours: 8)),
            likeCount: 56,
            replyCount: 25,
          ),
        ];

      case 'group_elderly':
        return [
          GroupDiscussion(
            id: 'disc_8',
            groupId: groupId,
            userName: '夕陽紅',
            content: '今天學了手機拍照，感覺自己又年輕了！',
            createdAt: now.subtract(const Duration(minutes: 45)),
            likeCount: 38,
            replyCount: 15,
          ),
          GroupDiscussion(
            id: 'disc_9',
            groupId: groupId,
            userName: '健康達人',
            content: '提醒大家注意最近的電話詐騙，手法又更新了...',
            createdAt: now.subtract(const Duration(hours: 2)),
            likeCount: 67,
            replyCount: 30,
          ),
        ];

      case 'group_medicine':
        return [
          GroupDiscussion(
            id: 'disc_10',
            groupId: groupId,
            userName: '用藥小助手',
            content: '降壓藥和哪些食物不能一起喫？整理了一份清單。',
            createdAt: now.subtract(const Duration(hours: 2)),
            likeCount: 42,
            replyCount: 18,
          ),
          GroupDiscussion(
            id: 'disc_11',
            groupId: groupId,
            userName: '健康守護者',
            content: '過期藥品如何正確處理？環保又安全的方法。',
            createdAt: now.subtract(const Duration(hours: 6)),
            likeCount: 35,
            replyCount: 12,
          ),
        ];

      case 'group_hospital':
        return [
          GroupDiscussion(
            id: 'disc_12',
            groupId: groupId,
            userName: '導診志願者',
            content: '市人民醫院最新掛號流程指南，包含線上預約步驟。',
            createdAt: now.subtract(const Duration(hours: 5)),
            likeCount: 89,
            replyCount: 35,
          ),
          GroupDiscussion(
            id: 'disc_13',
            groupId: groupId,
            userName: '熱心市民',
            content: '本週可以陪同就診，有需要的請聯繫我。',
            createdAt: now.subtract(const Duration(hours: 10)),
            likeCount: 23,
            replyCount: 8,
          ),
        ];

      default:
        return [];
    }
  }
}