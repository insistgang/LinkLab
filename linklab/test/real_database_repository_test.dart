import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/services/real_database_repository.dart';

void main() {
  test(
    'RealDatabaseRepository returns empty summary when database is disabled',
    () async {
      AppConfig.configureFromEnvironment(
        const {},
        enablePresenterSessionOnFallback: false,
      );

      final repository = const RealDatabaseRepository();
      final summary = await repository.fetchHomeSummary();

      expect(repository.isAvailable, isFalse);
      expect(summary.profile, isNull);
      expect(summary.helpRequests, isEmpty);
      expect(summary.volunteerProfile, isNull);
    },
  );

  test('RealMode minimal row parsers accept Supabase payloads', () {
    final now = DateTime.now().toIso8601String();

    final profile = RealProfile.fromJson({
      'id': 'user-1',
      'display_name': 'Alice',
      'role': 'volunteer',
      'phone': null,
      'created_at': now,
      'updated_at': now,
    });
    final request = RealHelpRequest.fromJson({
      'id': 'help-1',
      'seeker_id': 'user-1',
      'title': '出行協助',
      'description': '需要確認路線',
      'status': 'created',
      'latitude': null,
      'longitude': null,
      'created_at': now,
      'updated_at': now,
    });
    final volunteer = RealVolunteerProfile.fromJson({
      'id': 'volunteer-1',
      'user_id': 'user-1',
      'service_radius_m': 3000,
      'is_available': true,
      'created_at': now,
      'updated_at': now,
    });

    expect(profile.effectiveDisplayName, 'Alice');
    expect(profile.role, 'volunteer');
    expect(request.status, 'created');
    expect(request.title, '出行協助');
    expect(volunteer.serviceRadiusM, 3000);
    expect(volunteer.isAvailable, isTrue);
  });
}
