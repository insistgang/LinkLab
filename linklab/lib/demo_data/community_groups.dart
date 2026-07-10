import '../models/community_group_model.dart';
import '../widgets/demo/linkable_icon.dart';

/// 社区小组Demo数据
class CommunityGroupsData {
  /// 获取所有Demo小组
  static List<CommunityGroup> getAllGroups() {
    return [
      CommunityGroup(
        id: 'group_visual',
        name: '视障互助圈',
        description: '视障朋友交流日常生活经验，分享出行技巧和辅助工具使用心得。',
        icon: LinkableIconName.visualImpairment,
        memberCount: 1286,
        category: CommunityGroupCategory.visualImpairment,
        lastActiveTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      CommunityGroup(
        id: 'group_hearing',
        name: '听障交流圈',
        description: '听障伙伴分享沟通技巧、助听设备使用体验，互相支持鼓励。',
        icon: LinkableIconName.hearingImpairment,
        memberCount: 958,
        category: CommunityGroupCategory.hearingImpairment,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CommunityGroup(
        id: 'group_mobility',
        name: '轮椅出行圈',
        description: '轮椅使用者交流无障碍出行经验，分享坡道、电梯等设施信息。',
        icon: LinkableIconName.mobilityImpairment,
        memberCount: 723,
        category: CommunityGroupCategory.mobilityImpairment,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CommunityGroup(
        id: 'group_elderly',
        name: '老年关爱圈',
        description: '老年人健康生活交流，分享养生知识和防骗技巧。',
        icon: LinkableIconName.elderly,
        memberCount: 2156,
        category: CommunityGroupCategory.elderlyCare,
        lastActiveTime: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      CommunityGroup(
        id: 'group_medicine',
        name: '药品咨询圈',
        description: '药品使用经验分享，用药注意事项交流，互相提醒健康事项。',
        icon: LinkableIconName.medicineCheck,
        memberCount: 1567,
        category: CommunityGroupCategory.medicineConsult,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CommunityGroup(
        id: 'group_hospital',
        name: '导诊互助圈',
        description: '医院就诊经验分享，挂号流程指引，陪诊志愿者招募。',
        icon: LinkableIconName.navigationGuide,
        memberCount: 892,
        category: CommunityGroupCategory.hospitalGuide,
        lastActiveTime: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  /// 根据ID获取小组
  static CommunityGroup? getGroupById(String id) {
    try {
      return getAllGroups().firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取小组讨论列表
  static List<GroupDiscussion> getDiscussions(String groupId) {
    final now = DateTime.now();

    switch (groupId) {
      case 'group_visual':
        return [
          GroupDiscussion(
            id: 'disc_1',
            groupId: groupId,
            userName: '阳光行者',
            content: '今天用读屏软件成功在新超市购物了！分享一下经验...',
            createdAt: now.subtract(const Duration(minutes: 30)),
            likeCount: 24,
            replyCount: 8,
          ),
          GroupDiscussion(
            id: 'disc_2',
            groupId: groupId,
            userName: '独立生活家',
            content: '推荐一款很好用的盲文学习APP，界面简洁易操作。',
            createdAt: now.subtract(const Duration(hours: 2)),
            likeCount: 18,
            replyCount: 5,
          ),
          GroupDiscussion(
            id: 'disc_3',
            groupId: groupId,
            userName: '探索者',
            content: '周末有谁想去公园散步？可以一起交流出行心得。',
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
            userName: '静默舞者',
            content: '这款助听器降噪效果很好，推荐给大家！',
            createdAt: now.subtract(const Duration(hours: 1)),
            likeCount: 32,
            replyCount: 12,
          ),
          GroupDiscussion(
            id: 'disc_5',
            groupId: groupId,
            userName: '手语达人',
            content: '本周六有手语角活动，欢迎新手参加！',
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
            userName: '轮椅行者',
            content: '分享一个无障碍地图小程序，可以查看各地坡道信息。',
            createdAt: now.subtract(const Duration(hours: 3)),
            likeCount: 28,
            replyCount: 9,
          ),
          GroupDiscussion(
            id: 'disc_7',
            groupId: groupId,
            userName: '自由飞翔',
            content: '地铁站的无障碍电梯位置汇总，持续更新中...',
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
            userName: '夕阳红',
            content: '今天学了手机拍照，感觉自己又年轻了！',
            createdAt: now.subtract(const Duration(minutes: 45)),
            likeCount: 38,
            replyCount: 15,
          ),
          GroupDiscussion(
            id: 'disc_9',
            groupId: groupId,
            userName: '健康达人',
            content: '提醒大家注意最近的电话诈骗，手法又更新了...',
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
            userName: '用药小助手',
            content: '降压药和哪些食物不能一起吃？整理了一份清单。',
            createdAt: now.subtract(const Duration(hours: 2)),
            likeCount: 42,
            replyCount: 18,
          ),
          GroupDiscussion(
            id: 'disc_11',
            groupId: groupId,
            userName: '健康守护者',
            content: '过期药品如何正确处理？环保又安全的方法。',
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
            userName: '导诊志愿者',
            content: '市人民医院最新挂号流程指南，包含线上预约步骤。',
            createdAt: now.subtract(const Duration(hours: 5)),
            likeCount: 89,
            replyCount: 35,
          ),
          GroupDiscussion(
            id: 'disc_13',
            groupId: groupId,
            userName: '热心市民',
            content: '本周可以陪同就诊，有需要的请联系我。',
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