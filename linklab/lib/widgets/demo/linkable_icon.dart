import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LinkableIconName {
  add('add', '添加'),
  aiAssistant('ai_assistant', 'AI助手'),
  aiChat('ai_chat', 'AI 對話'),
  answer('answer', '接聽'),
  asyncNote('async_note', '留言'),
  back('back', '返回'),
  both('both', '兩者皆是'),
  broadcast('broadcast', '廣播'),
  cancel('cancel', '撤銷'),
  colorIdentify('color_identify', '顏色識別'),
  community('community', '社羣'),
  completed('completed', '已完成'),
  dailyStory('daily_story', '社羣每日故事'),
  darkMode('dark_mode', '夜間模式'),
  date('date', '日期'),
  deafRelay('deaf_relay', '聽障轉譯'),
  defaultAvatar('default_avatar', '用戶原始頭像'),
  delete('delete', '刪除'),
  elderly('elderly', '老年人'),
  emergency('emergency', '緊急求助'),
  emergencyContact('emergency_contact', '緊急聯繫人'),
  emergencyDetect('emergency_detect', '緊急識別'),
  expired('expired', '超時'),
  favorite('favorite', '收藏'),
  featuredStory('featured_story', '精選故事'),
  fontSize('font_size', '字體調節'),
  forward('forward', '轉發'),
  group('group', '社羣小組'),
  haptic('haptic', '觸覺反饋'),
  hangUp('hang_up', '掛斷'),
  hearingImpairment('hearing_impairment', '聽力障礙'),
  help('help', '幫助'),
  helpHistory('help_history', '我的求助歷史'),
  highContrast('high_contrast', '高對比度'),
  home('home', '首頁'),
  humanHandoff('human_handoff', '轉人工'),
  like('like', '點贊'),
  lightMode('light_mode', '白天模式'),
  locationShare('location_share', '位置共享'),
  matching('matching', '匹配中'),
  medicineCheck('medicine_check', '藥品確認'),
  message('message', '消息'),
  mobilityImpairment('mobility_impairment', '肢體障礙'),
  moneyIdentify('money_identify', '鈔票識別'),
  mute('mute', '靜音'),
  navigationGuide('navigation_guide', '導航導診'),
  needHelp('need_help', '我需要幫助'),
  notification('notification', '通知'),
  objectIdentify('object_identify', '物體識別'),
  ocrText('ocr_text', '讀文字'),
  personalProfile('personal_profile', '個人檔案'),
  personalizedExperience('personalized_experience', '個性化使用體驗'),
  photoHelp('photo_help', '拍照求助'),
  points('points', '積分'),
  processing('processing', '處理中'),
  profile('profile', '個人中心'),
  report('report', '舉報'),
  safetyReady('safety_ready', '安全就緒度'),
  saveSettings('save_settings', '保存設置'),
  scan('scan', '掃一掃'),
  sceneDescribe('scene_describe', '場景描述'),
  screenReader('screen_reader', '讀屏'),
  search('search', '搜索'),
  selectDisability('select_disability', '請選擇你的障礙類型'),
  send('send', '發送'),
  settings('settings', '設置'),
  signLanguage('sign_language', '手語識別'),
  speechImpairment('speech_impairment', '言語障礙'),
  speechToText('speech_to_text', '語音轉文字'),
  tempHelp('temp_help', '臨時需要幫助'),
  textHelp('text_help', '文字求助'),
  translateRelay('translate_relay', '翻譯代述'),
  tts('tts', '語音輸出'),
  unknown('unknown', '不確定'),
  vibrationFlash('vibration_flash', '震動閃光提醒'),
  visualImpairment('visual_impairment', '視力障礙'),
  voiceCall('voice_call', '語音通話'),
  voiceHelp('voice_help', '語音求助'),
  voiceInput('voice_input', '語音輸入'),
  volunteerMatch('volunteer_match', '志願者匹配'),
  volunteerRole('volunteer_role', '我是志願者'),
  wantToHelp('want_to_help', '我想幫助他人'),
  weather('weather', '天氣'),
  weakSignal('weak_signal', '弱網');

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
