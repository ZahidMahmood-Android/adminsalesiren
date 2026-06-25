import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_logger.dart';
import '../../../../core/services/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_bug_reports_repository.dart';
import '../../domain/entities/bug_report.dart';
import '../../domain/repositories/bug_reports_repository.dart';

final bugReportsRepositoryProvider = Provider<BugReportsRepository>((ref) {
  return FirebaseBugReportsRepository(ref.watch(firestoreProvider));
});

final bugReportsProvider = StreamProvider.autoDispose<List<BugReport>>((
  ref,
) async* {
  yield const <BugReport>[];
  yield* ref.watch(bugReportsRepositoryProvider).watchBugReports();
});

final bugReportActionsProvider =
    AsyncNotifierProvider.autoDispose<BugReportActionsController, void>(
      BugReportActionsController.new,
    );

class BugReportActionsController extends AsyncNotifier<void> {
  final _log = AppLogger.get('BugReportActionsController');

  @override
  FutureOr<void> build() {}

  Future<void> markResolved(String id) async {
    final userId = ref.read(currentUserProvider)?.id;
    _log.info('Mark bug resolved id=$id');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bugReportsRepositoryProvider)
          .updateStatus(id: id, status: 'resolved', resolvedBy: userId),
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final userId = ref.read(currentUserProvider)?.id;
    _log.info('Update bug status id=$id status=$status');
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bugReportsRepositoryProvider)
          .updateStatus(
            id: id,
            status: status,
            resolvedBy: status == 'resolved' ? userId : null,
          ),
    );
  }
}

final bugReportSubmittingProvider =
    NotifierProvider.autoDispose<BugReportSubmitting, bool>(
      BugReportSubmitting.new,
    );

class BugReportSubmitting extends Notifier<bool> {
  @override
  bool build() => false;

  void setValue(bool value) => state = value;
}

final selectedAdminBugCategoryProvider =
    NotifierProvider.autoDispose<SelectedAdminBugCategory, String>(
      SelectedAdminBugCategory.new,
    );

class SelectedAdminBugCategory extends Notifier<String> {
  @override
  String build() => 'crash';

  void select(String value) => state = value;
}
