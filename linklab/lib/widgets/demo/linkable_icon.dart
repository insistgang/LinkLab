import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LinkableIconName {
  home('home', '首页'),
  aiChat('ai_chat', 'AI 对话'),
  volunteerMatch('volunteer_match', '志愿者匹配'),
  voiceCall('voice_call', '语音通话'),
  profile('profile', '个人中心'),
  featuredStory('featured_story', '精选故事'),
  needHelp('need_help', '我需要帮助'),
  photoHelp('photo_help', '拍照求助'),
  textHelp('text_help', '文字求助'),
  voiceHelp('voice_help', '语音求助'),
  locationShare('location_share', '位置共享'),
  humanHandoff('human_handoff', '转人工'),
  ocrText('ocr_text', '读文字'),
  sceneDescribe('scene_describe', '场景描述'),
  objectIdentify('object_identify', '物体识别'),
  colorIdentify('color_identify', '颜色识别'),
  moneyIdentify('money_identify', '钞票识别'),
  translateRelay('translate_relay', '翻译代述'),
  navigationGuide('navigation_guide', '导航导诊'),
  medicineCheck('medicine_check', '药品确认'),
  emergency('emergency', '紧急求助'),
  unknown('unknown', '不确定'),
  deafRelay('deaf_relay', '听障转译'),
  scan('scan', '扫一扫'),
  emergencyContact('emergency_contact', '紧急联系人'),
  cancel('cancel', '撤销'),
  broadcast('broadcast', '广播'),
  answer('answer', '接听'),
  hangUp('hang_up', '挂断'),
  mute('mute', '静音'),
  fontSize('font_size', '字体调节'),
  highContrast('high_contrast', '高对比度'),
  screenReader('screen_reader', '读屏'),
  tts('tts', '语音输出'),
  haptic('haptic', '触觉反馈'),
  darkMode('dark_mode', '夜间模式'),
  visualImpairment('visual_impairment', '视力障碍'),
  hearingImpairment('hearing_impairment', '听力障碍'),
  mobilityImpairment('mobility_impairment', '肢体障碍'),
  elderly('elderly', '老年人'),
  speechImpairment('speech_impairment', '言语障碍'),
  volunteerRole('volunteer_role', '我是志愿者'),
  processing('processing', '处理中'),
  matching('matching', '匹配中'),
  completed('completed', '已完成'),
  expired('expired', '超时'),
  asyncNote('async_note', '留言'),
  weakSignal('weak_signal', '弱网');

  const LinkableIconName(this.fileName, this.label);

  final String fileName;
  final String label;

  String get assetPath => 'assets/icons/linkable/$fileName.svg';
}

class LinkableSvgIcon extends StatelessWidget {
  const LinkableSvgIcon({
    super.key,
    required this.icon,
    this.size = 32,
    this.semanticLabel,
    this.fit = BoxFit.contain,
  });

  final LinkableIconName icon;
  final double size;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = SvgPicture.asset(
      icon.assetPath,
      width: size,
      height: size,
      fit: fit,
      excludeFromSemantics: true,
    );

    final label = semanticLabel ?? icon.label;
    return Semantics(image: true, label: label, child: image);
  }
}

class LinkableMaterialIcon extends StatelessWidget {
  const LinkableMaterialIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final linkableIcon = linkableIconForMaterial(icon);
    if (linkableIcon != null) {
      return LinkableSvgIcon(
        icon: linkableIcon,
        size: size,
        semanticLabel: semanticLabel,
      );
    }

    return LinkableSvgIcon(
      icon: LinkableIconName.unknown,
      size: size,
      semanticLabel: semanticLabel ?? LinkableIconName.unknown.label,
    );
  }
}

LinkableIconName? linkableIconForMaterial(IconData? icon) {
  if (icon == null) return null;

  if (_matches(icon, const [Icons.home, Icons.home_outlined])) {
    return LinkableIconName.home;
  }

  if (_matches(icon, const [
    Icons.touch_app_rounded,
    Icons.rocket_launch_outlined,
    Icons.help_outline_rounded,
    Icons.add,
    Icons.bolt_outlined,
  ])) {
    return LinkableIconName.needHelp;
  }

  if (_matches(icon, const [
    Icons.smart_toy,
    Icons.smart_toy_outlined,
    Icons.psychology,
    Icons.psychology_alt_outlined,
    Icons.multitrack_audio,
    Icons.multitrack_audio_rounded,
    Icons.headset_mic_outlined,
    Icons.auto_awesome_outlined,
  ])) {
    return LinkableIconName.aiChat;
  }

  if (_matches(icon, const [
    Icons.forum,
    Icons.forum_outlined,
    Icons.auto_stories,
    Icons.auto_stories_outlined,
    Icons.history_outlined,
    Icons.history_rounded,
    Icons.history_toggle_off,
  ])) {
    return LinkableIconName.featuredStory;
  }

  if (_matches(icon, const [
    Icons.person,
    Icons.person_outline,
    Icons.badge_outlined,
    Icons.person_add_alt_1,
  ])) {
    return LinkableIconName.profile;
  }

  if (_matches(icon, const [
    Icons.volunteer_activism,
    Icons.volunteer_activism_outlined,
    Icons.groups,
    Icons.groups_outlined,
    Icons.people_alt_outlined,
    Icons.people_outline,
    Icons.person_search_outlined,
    Icons.recommend_outlined,
  ])) {
    return LinkableIconName.volunteerMatch;
  }

  if (_matches(icon, const [
    Icons.phone,
    Icons.call,
    Icons.call_outlined,
    Icons.phone_in_talk,
    Icons.phone_in_talk_outlined,
    Icons.videocam_outlined,
    Icons.wifi_tethering_outlined,
  ])) {
    return LinkableIconName.voiceCall;
  }

  if (_matches(icon, const [Icons.call_end, Icons.phone_disabled_outlined])) {
    return LinkableIconName.hangUp;
  }

  if (_matches(icon, const [
    Icons.mic_off,
    Icons.mic_off_outlined,
    Icons.mic_none_rounded,
  ])) {
    return LinkableIconName.mute;
  }

  if (_matches(icon, const [
    Icons.mic,
    Icons.record_voice_over_outlined,
    Icons.volume_up_outlined,
    Icons.volume_up,
    Icons.volume_down,
  ])) {
    return LinkableIconName.voiceHelp;
  }

  if (_matches(icon, const [
    Icons.document_scanner_outlined,
    Icons.edit_note_outlined,
    Icons.article,
    Icons.mark_email_read_outlined,
    Icons.markunread_outlined,
    Icons.label_important_outline,
  ])) {
    return LinkableIconName.ocrText;
  }

  if (_matches(icon, const [
    Icons.camera_alt_outlined,
    Icons.camera_alt,
    Icons.image_outlined,
    Icons.photo_outlined,
    Icons.photo_library_outlined,
  ])) {
    return LinkableIconName.photoHelp;
  }

  if (_matches(icon, const [
    Icons.chat_bubble_outline,
    Icons.chat_bubble_outline_rounded,
    Icons.add_comment_outlined,
    Icons.edit_outlined,
    Icons.send,
    Icons.send_outlined,
  ])) {
    return LinkableIconName.textHelp;
  }

  if (_matches(icon, const [Icons.color_lens_outlined, Icons.color_lens])) {
    return LinkableIconName.colorIdentify;
  }

  if (_matches(icon, const [
    Icons.visibility,
    Icons.visibility_outlined,
    Icons.remove_red_eye,
  ])) {
    return LinkableIconName.sceneDescribe;
  }

  if (_matches(icon, const [
    Icons.medication_outlined,
    Icons.medical_services_outlined,
  ])) {
    return LinkableIconName.medicineCheck;
  }

  if (_matches(icon, const [
    Icons.location_city,
    Icons.location_on_outlined,
    Icons.location_off_outlined,
    Icons.my_location,
    Icons.near_me_outlined,
    Icons.place_outlined,
  ])) {
    return LinkableIconName.locationShare;
  }

  if (_matches(icon, const [
    Icons.navigation,
    Icons.arrow_back,
    Icons.arrow_back_ios,
    Icons.arrow_forward,
    Icons.arrow_forward_rounded,
    Icons.radar_outlined,
    Icons.filter_alt_outlined,
  ])) {
    return LinkableIconName.navigationGuide;
  }

  if (_matches(icon, const [
    Icons.warning_amber_rounded,
    Icons.warning_amber_outlined,
    Icons.emergency,
    Icons.emergency_outlined,
    Icons.report_problem,
    Icons.error_outline,
    Icons.info_outline,
    Icons.privacy_tip_outlined,
    Icons.shield_outlined,
  ])) {
    return LinkableIconName.emergency;
  }

  if (_matches(icon, const [
    Icons.notifications_off_outlined,
    Icons.campaign_outlined,
  ])) {
    return LinkableIconName.broadcast;
  }

  if (_matches(icon, const [
    Icons.close,
    Icons.cancel_outlined,
    Icons.delete_outline,
    Icons.logout_rounded,
  ])) {
    return LinkableIconName.cancel;
  }

  if (_matches(icon, const [
    Icons.check_circle,
    Icons.check_circle_rounded,
    Icons.check_circle_outline,
    Icons.assignment_turned_in_outlined,
    Icons.verified_user_outlined,
    Icons.save_outlined,
  ])) {
    return LinkableIconName.completed;
  }

  if (_matches(icon, const [
    Icons.pending_outlined,
    Icons.sync_outlined,
    Icons.hourglass_empty,
    Icons.hourglass_empty_outlined,
    Icons.hourglass_top_outlined,
    Icons.refresh_outlined,
    Icons.refresh_rounded,
    Icons.restart_alt_outlined,
    Icons.stop_circle,
    Icons.fiber_manual_record,
  ])) {
    return LinkableIconName.processing;
  }

  if (_matches(icon, const [
    Icons.timer,
    Icons.timer_outlined,
    Icons.timer_off_outlined,
    Icons.event_busy_outlined,
    Icons.schedule_outlined,
    Icons.group_off_outlined,
    Icons.radio_button_unchecked_rounded,
  ])) {
    return LinkableIconName.expired;
  }

  if (_matches(icon, const [
    Icons.wifi_off_outlined,
    Icons.cloud_off_outlined,
    Icons.signal_cellular_off,
    Icons.signal_cellular_alt_1_bar,
    Icons.signal_cellular_alt_2_bar,
  ])) {
    return LinkableIconName.weakSignal;
  }

  if (_matches(icon, const [
    Icons.accessibility_new_rounded,
    Icons.accessibility_new_outlined,
    Icons.settings_accessibility_rounded,
    Icons.settings_accessibility_outlined,
    Icons.settings_accessibility,
    Icons.tune_rounded,
  ])) {
    return LinkableIconName.screenReader;
  }

  if (_matches(icon, const [Icons.visibility_off_outlined])) {
    return LinkableIconName.visualImpairment;
  }

  if (_matches(icon, const [
    Icons.hearing_outlined,
    Icons.hearing_disabled_outlined,
  ])) {
    return LinkableIconName.hearingImpairment;
  }

  if (_matches(icon, const [Icons.accessible_outlined])) {
    return LinkableIconName.mobilityImpairment;
  }

  if (_matches(icon, const [Icons.elderly_outlined])) {
    return LinkableIconName.elderly;
  }

  if (_matches(icon, const [Icons.contrast_outlined])) {
    return LinkableIconName.highContrast;
  }

  if (_matches(icon, const [Icons.calendar_today_outlined])) {
    return LinkableIconName.completed;
  }

  if (_matches(icon, const [
    Icons.dark_mode,
    Icons.dark_mode_outlined,
    Icons.light_mode,
    Icons.light_mode_outlined,
    Icons.wb_sunny_outlined,
  ])) {
    return LinkableIconName.darkMode;
  }

  if (_matches(icon, const [Icons.text_fields_outlined])) {
    return LinkableIconName.fontSize;
  }

  if (_matches(icon, const [
    Icons.contact_emergency_outlined,
    Icons.contact_phone_outlined,
    Icons.contacts,
    Icons.contacts_outlined,
    Icons.favorite,
    Icons.favorite_border,
    Icons.favorite_rounded,
    Icons.share,
  ])) {
    return LinkableIconName.emergencyContact;
  }

  if (_matches(icon, const [
    Icons.star,
    Icons.star_border,
    Icons.star_outline,
  ])) {
    return LinkableIconName.completed;
  }

  if (_matches(icon, const [Icons.mic_outlined, Icons.volume_off_outlined])) {
    return LinkableIconName.mute;
  }

  return null;
}

bool _matches(IconData icon, List<IconData> candidates) {
  return candidates.any((candidate) => icon == candidate);
}
