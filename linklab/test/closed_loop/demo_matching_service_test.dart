@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/models/demo_match_request.dart';
import 'package:linklab/models/demo_volunteer.dart';
import 'package:linklab/providers/demo_services_provider.dart';
import 'package:linklab/services/demo/demo_data_loader.dart';
import 'package:linklab/services/demo/demo_matching_service.dart';

import 'test_harness.dart';

void main() {
  const hospitalRequest = DemoMatchRequest(
    requestId: 'match_hospital',
    queryText: '我在醫院找不到科室，掛號後不知道取藥窗口怎麼走',
    requestType: 'hospital',
    urgencyLevel: 'medium',
  );

  const medicationRequest = DemoMatchRequest(
    requestId: 'match_medication',
    queryText: '幫我確認藥品說明書，這個藥怎麼喫，一次幾片',
    requestType: 'medication',
    urgencyLevel: 'normal',
  );

  const hearingRequest = DemoMatchRequest(
    requestId: 'match_hearing',
    queryText: '外賣電話我聽不清，需要幫我轉譯取件碼',
    requestType: 'hearing',
    urgencyLevel: 'normal',
  );

  const visualRequest = DemoMatchRequest(
    requestId: 'match_visual',
    queryText: '我看不見前面路況，有沒有障礙物',
    requestType: 'visual',
    urgencyLevel: 'medium',
  );

  const elderlyRequest = DemoMatchRequest(
    requestId: 'match_elderly',
    queryText: '老人需要陪同，想慢慢走到出口',
    requestType: 'elderly',
    urgencyLevel: 'normal',
  );

  test('demo_volunteers.json 可以加載，並滿足本地 demo 數據基線', () async {
    await prepareEmptyDemoEnvironment();

    expect(
      await rootBundle.loadString('assets/demo_data/demo_volunteers.json'),
      contains('demo_volunteer_001'),
    );

    final rawVolunteers = DemoDataLoader.getMatchingDemoVolunteers();
    expect(rawVolunteers.length, greaterThanOrEqualTo(8));

    final volunteers = rawVolunteers.map(DemoVolunteer.fromJson).toList();
    final onlineCount = volunteers.where((item) => item.isOnline).length;
    expect(onlineCount, greaterThanOrEqualTo(6));
    expect(
      volunteers.where((item) => item.skills.contains(demoSkillHospitalGuide)),
      hasLength(greaterThanOrEqualTo(2)),
    );
    expect(
      volunteers.any((item) => item.skills.contains(demoSkillMedicationHelp)),
      isTrue,
    );
    expect(
      volunteers.any(
        (item) => item.skills.contains(demoSkillHearingCommunication),
      ),
      isTrue,
    );
    expect(
      volunteers.any((item) => item.skills.contains(demoSkillVisualAssistance)),
      isTrue,
    );
    expect(
      volunteers.any((item) => item.skills.contains(demoSkillElderlyCompanion)),
      isTrue,
    );
  });

  test('Top 5 只返回在線志願者，且數量最多爲 5', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final allVolunteers = await service.loadVolunteers();
    final offlineIds = allVolunteers
        .where((volunteer) => !volunteer.isOnline)
        .map((volunteer) => volunteer.id)
        .toSet();

    final response = await service.matchTopVolunteers(hospitalRequest);
    expect(response.usesTopFive, isTrue);
    expect(response.results.length, lessThanOrEqualTo(5));
    expect(response.results, isNotEmpty);
    expect(
      response.results.any(
        (result) => offlineIds.contains(result.volunteer.id),
      ),
      isFalse,
    );
  });

  test('醫院導診需求優先匹配醫院導診技能', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(hospitalRequest);

    expect(
      response.results.first.volunteer.skills,
      contains(demoSkillHospitalGuide),
    );
    expect(
      response.results.first.matchedSkills,
      contains(demoSkillHospitalGuide),
    );
    expect(response.results.first.reason, contains(demoSkillHospitalGuide));
  });

  test('藥品確認需求優先匹配藥品說明協助技能', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(medicationRequest);

    expect(
      response.results.first.volunteer.skills,
      contains(demoSkillMedicationHelp),
    );
    expect(
      response.results.first.matchedSkills,
      contains(demoSkillMedicationHelp),
    );
  });

  test('聽障和電話需求優先匹配手語或聽障溝通技能', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(hearingRequest);

    expect(
      response.results.first.volunteer.skills,
      contains(demoSkillHearingCommunication),
    );
    expect(
      response.results.first.matchedSkills,
      contains(demoSkillHearingCommunication),
    );
  });

  test('視障和路況需求優先匹配視障協助技能', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(visualRequest);

    expect(
      response.results.first.volunteer.skills,
      contains(demoSkillVisualAssistance),
    );
    expect(
      response.results.first.matchedSkills,
      contains(demoSkillVisualAssistance),
    );
  });

  test('老人陪同需求優先匹配老人陪同技能', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(elderlyRequest);

    expect(
      response.results.first.volunteer.skills,
      contains(demoSkillElderlyCompanion),
    );
    expect(
      response.results.first.matchedSkills,
      contains(demoSkillElderlyCompanion),
    );
  });

  test('SOS 請求不走普通 F9 Top 5 匹配公式', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(
      const DemoMatchRequest(
        requestId: 'match_sos',
        queryText: '救命，我摔倒了',
        requestType: 'sos',
        urgencyLevel: 'high',
        isSos: true,
      ),
    );

    expect(response.usesTopFive, isFalse);
    expect(response.results, isEmpty);
    expect(response.message, contains('F13'));
    expect(response.message, contains('不使用普通 Top 5 匹配'));
  });

  test('同分時距離更近者優先', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();

    final response = await service.matchTopVolunteers(
      const DemoMatchRequest(
        requestId: 'match_tie',
        queryText: '普通問路',
        requestType: 'directions',
        urgencyLevel: 'normal',
        preferredSkills: [demoSkillGeneralDirections],
      ),
      volunteerPool: const [
        DemoVolunteer(
          id: 'tie_far',
          nickname: '遠一點',
          avatarLabel: '遠',
          distanceMeters: 101,
          skills: [demoSkillGeneralDirections],
          reputationScore: 0.9005,
          isOnline: true,
          helpCount: 10,
          estimatedResponseSeconds: 10,
        ),
        DemoVolunteer(
          id: 'tie_near',
          nickname: '近一點',
          avatarLabel: '近',
          distanceMeters: 100,
          skills: [demoSkillGeneralDirections],
          reputationScore: 0.9,
          isOnline: true,
          helpCount: 10,
          estimatedResponseSeconds: 10,
        ),
      ],
    );

    expect(response.results, hasLength(2));
    expect(response.results.first.score, response.results.last.score);
    expect(response.results.first.volunteer.id, 'tie_near');
  });

  test('多人搶單最終只能一個 active volunteer，拒接後可嘗試下一位', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();
    final response = await service.matchTopVolunteers(hospitalRequest);
    final firstVolunteerId = response.results[0].volunteer.id;
    final secondVolunteerId = response.results[1].volunteer.id;

    final firstAccept = service.tryAccept(firstVolunteerId);
    final secondAccept = service.tryAccept(secondVolunteerId);

    expect(firstAccept.success, isTrue);
    expect(firstAccept.activeVolunteerId, firstVolunteerId);
    expect(secondAccept.success, isFalse);
    expect(secondAccept.message, contains(firstVolunteerId));
    expect(service.activeVolunteerId, firstVolunteerId);

    service.resetCompetition();
    final reject = service.rejectOrTimeout(firstVolunteerId);
    final nextAccept = service.tryAccept(secondVolunteerId);

    expect(reject.success, isTrue);
    expect(nextAccept.success, isTrue);
    expect(nextAccept.activeVolunteerId, secondVolunteerId);
  });

  test('cancel 和 expire 邏輯可用', () async {
    await prepareEmptyDemoEnvironment();

    final cancelledService = DemoMatchingEngineService();
    final cancel = cancelledService.cancel();
    final acceptAfterCancel = cancelledService.tryAccept('demo_volunteer_001');
    expect(cancel.success, isTrue);
    expect(cancelledService.isCancelled, isTrue);
    expect(acceptAfterCancel.success, isFalse);
    expect(acceptAfterCancel.message, contains('取消'));

    final expiredService = DemoMatchingEngineService();
    final expire = expiredService.expire();
    final acceptAfterExpire = expiredService.tryAccept('demo_volunteer_001');
    expect(expire.success, isTrue);
    expect(expiredService.isExpired, isTrue);
    expect(acceptAfterExpire.success, isFalse);
    expect(acceptAfterExpire.message, contains('過期'));
  });

  test('無真實 API key、無真實 Supabase 時 matching service 仍可運行', () async {
    await prepareEmptyDemoEnvironment();
    expect(AppConfig.demoMode, isTrue);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(demoMatchingEngineProvider);
    final response = await service.matchTopVolunteers(hospitalRequest);

    expect(response.results, isNotEmpty);
    expect(response.message, contains('Top 5'));
  });

  test('50 人本地池匹配計算保持輕量', () async {
    await prepareEmptyDemoEnvironment();
    final service = DemoMatchingEngineService();
    final pool = List<DemoVolunteer>.generate(50, (index) {
      return DemoVolunteer(
        id: 'perf_$index',
        nickname: '性能志願者$index',
        avatarLabel: '測',
        distanceMeters: 100 + index * 20,
        skills: index.isEven
            ? const [demoSkillHospitalGuide, demoSkillMedicationHelp]
            : const [demoSkillGeneralDirections, demoSkillVisualAssistance],
        reputationScore: 0.8 + (index % 10) * 0.01,
        isOnline: true,
        helpCount: 20 + index,
        estimatedResponseSeconds: 6 + (index % 20),
      );
    });

    final stopwatch = Stopwatch()..start();
    final response = await service.matchTopVolunteers(
      hospitalRequest,
      volunteerPool: pool,
    );
    stopwatch.stop();

    expect(response.results, hasLength(5));
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
}
