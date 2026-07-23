import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readRepositoryFile(String relativePath) {
  return File('../$relativePath').readAsStringSync();
}

List<String> _repositoryFiles(String relativePath) {
  final directory = Directory('../$relativePath');
  if (!directory.existsSync()) return const [];

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path.replaceFirst('../', ''))
      .toList()
    ..sort();
}

void main() {
  test('活跃 migration 只保留最小三表 RealMode 基线', () {
    final activeMigrations = _repositoryFiles('supabase/migrations');
    final baseline = _readRepositoryFile(
      'supabase/migrations/202605240001_realmode_phase3_minimal_crud.sql',
    );

    expect(activeMigrations, [
      'supabase/migrations/202605240001_realmode_phase3_minimal_crud.sql',
    ]);
    expect(baseline, contains('create table if not exists public.profiles'));
    expect(
      baseline,
      contains('create table if not exists public.help_requests'),
    );
    expect(
      baseline,
      contains('create table if not exists public.volunteer_profiles'),
    );
    expect(baseline, contains('references auth.users(id)'));
    expect(baseline, isNot(contains('create table users')));
    expect(baseline, isNot(contains('point_transactions')));
    expect(baseline, isNot(contains('async_tasks')));
  });

  test('活跃部署面不声明任何未对齐的 Edge Function', () {
    final rootConfig = _readRepositoryFile('supabase/config.toml');

    expect(_repositoryFiles('supabase/functions'), isEmpty);
    expect(rootConfig, isNot(contains('[functions.')));
    expect(rootConfig, contains('当前不声明可部署 Edge Function'));
  });

  test('历史迁移与函数保留在 legacy 且有禁止部署说明', () {
    final legacyReadme = _readRepositoryFile('supabase/legacy/README.md');
    final legacyFiles = _repositoryFiles('supabase/legacy');

    expect(legacyReadme, contains('不要从本目录执行 `supabase db push`'));
    expect(
      legacyFiles,
      contains('supabase/legacy/migrations/001_create_tables.sql'),
    );
    expect(
      legacyFiles,
      contains(
        'supabase/legacy/migrations/202607230001_harden_edge_functions.sql',
      ),
    );
    expect(
      legacyFiles,
      contains('supabase/legacy/functions/matching-engine/index.ts'),
    );
    expect(
      legacyFiles,
      contains('supabase/legacy/functions/push-notifier/index.ts'),
    );
    expect(
      legacyFiles,
      contains('supabase/legacy/functions/points-calculator/index.ts'),
    );
    expect(
      legacyFiles,
      contains('supabase/legacy/functions/ai-dispatcher/index.ts'),
    );
  });
}
