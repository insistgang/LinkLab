import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readRepositoryFile(String relativePath) {
  return File('../$relativePath').readAsStringSync();
}

void main() {
  test('所有部署中的 Edge Function 都必须启用 JWT 网关校验', () {
    final rootConfig = _readRepositoryFile('supabase/config.toml');
    final pointsConfig = _readRepositoryFile(
      'supabase/functions/points-calculator/config.toml',
    );

    expect(
      RegExp(
        r'\[functions\.points-calculator\]\s+verify_jwt\s*=\s*true',
      ).hasMatch(rootConfig),
      isTrue,
    );
    expect(pointsConfig, contains('verify_jwt = true'));
    expect(rootConfig, isNot(contains('verify_jwt = false')));
  });

  test('积分写入仅接受 service-role 调用且由数据库保证幂等', () {
    final implementation = _readRepositoryFile(
      'supabase/functions/points-calculator/index.ts',
    );
    final migration = _readRepositoryFile(
      'supabase/migrations/202607230001_harden_edge_functions.sql',
    );

    expect(implementation, contains('requireServiceRoleRequest'));
    expect(implementation, contains('award_volunteer_points_once'));
    expect(implementation, isNot(contains("supabase.rpc('increment'")));
    expect(migration, contains('point_transactions_source_record_unique'));
    expect(migration, contains('award_volunteer_points_once'));
  });

  test('匹配接口必须从 JWT 获取调用者并绑定资源归属', () {
    final implementation = _readRepositoryFile(
      'supabase/functions/matching-engine/index.ts',
    );

    expect(implementation, contains('authenticateRequest'));
    expect(implementation, contains('request.seekerId !== user.id'));
    expect(implementation, contains('helpRequest.seeker_id !== user.id'));
    expect(implementation, contains('volunteerId !== user.id'));
  });

  test('推送接口必须鉴权并验证 SOS 记录属于调用者', () {
    final implementation = _readRepositoryFile(
      'supabase/functions/push-notifier/index.ts',
    );

    expect(implementation, contains('authenticateRequest'));
    expect(implementation, contains('requireServiceRoleRequest'));
    expect(implementation, contains('authorizeSOSRequest'));
    expect(implementation, contains('helpRequest.seeker_id !== user.id'));
  });
}
