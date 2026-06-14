import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../data/repositories/firebase_reports_repository.dart';
import '../../domain/entities/offer_report.dart';
import '../../domain/repositories/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return FirebaseReportsRepository(ref.watch(firestoreProvider));
});

final reportsProvider = StreamProvider.autoDispose<List<OfferReport>>((
  ref,
) async* {
  yield const <OfferReport>[];
  yield* ref.watch(reportsRepositoryProvider).watchReports();
});

final reportActionsProvider =
    AsyncNotifierProvider.autoDispose<ReportActionsController, void>(
      ReportActionsController.new,
    );

class ReportActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('ReportActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> updateStatus(String id, String status) async {
    _log.info('Update report status action started id=$id status=$status');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reportsRepositoryProvider).updateReportStatus(id, status),
    );
    if (state.hasError) {
      _log.severe(
        'Update report status action failed id=$id',
        state.error,
        state.stackTrace,
      );
    } else {
      _log.info('Update report status action completed id=$id');
    }
  }

  Future<void> delete(String id) async {
    _log.warning('Delete report action started id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reportsRepositoryProvider).deleteReport(id),
    );
    if (state.hasError) {
      _log.severe(
        'Delete report action failed id=$id',
        state.error,
        state.stackTrace,
      );
    } else {
      _log.info('Delete report action completed id=$id');
    }
  }
}
