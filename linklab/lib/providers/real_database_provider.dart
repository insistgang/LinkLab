import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/real_database_repository.dart';

final realDatabaseRepositoryProvider = Provider<RealDatabaseRepository>((ref) {
  return const RealDatabaseRepository();
});

final realHomeSummaryProvider = FutureProvider.autoDispose<RealHomeSummary>((
  ref,
) {
  return ref.read(realDatabaseRepositoryProvider).fetchHomeSummary();
});
