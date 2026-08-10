import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/presentation/pages/approvals_screen.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

Response<dynamic> _envelope(String path, dynamic data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: data,
  );
}

Map<String, dynamic> _pendingPostJson({
  String id = '1',
  String action = 'schedule',
}) {
  return <String, dynamic>{
    'id': id,
    'title': 'Draft awaiting review',
    'content': 'Body text.',
    'status': 'draft',
    'approval_status': 'pending',
    'approval_requested_action': action,
    'user': <String, dynamic>{'id': 9, 'name': 'Editor Person'},
  };
}

Future<void> _pump(WidgetTester tester, PostRepositoryImpl repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        postRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: ApprovalsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a distinct empty state when nothing is pending', (
    tester,
  ) async {
    final repository = PostRepositoryImpl(
      networkClient: FakeNetworkClient(
        getHandler: (path) async {
          expect(path, contains('approval_status=pending'));
          return _envelope(path, <String, dynamic>{
            'success': true,
            'data': <dynamic>[],
          });
        },
      ),
    );

    await _pump(tester, repository);

    expect(
      find.text('Nothing is waiting for approval right now.'),
      findsOneWidget,
    );
  });

  testWidgets('renders the requested action and requester for a pending post', (
    tester,
  ) async {
    final repository = PostRepositoryImpl(
      networkClient: FakeNetworkClient(
        getHandler: (path) async {
          return _envelope(path, <String, dynamic>{
            'success': true,
            'data': <dynamic>[_pendingPostJson(action: 'publish_now')],
          });
        },
      ),
    );

    await _pump(tester, repository);

    expect(find.text('Draft awaiting review'), findsOneWidget);
    expect(find.text('Requested by Editor Person'), findsOneWidget);
    expect(find.text('Requested: publish now'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Approve'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsOneWidget);
  });

  testWidgets(
    'tapping Approve calls the approve endpoint and removes the card',
    (tester) async {
      var approveCalled = false;
      final repository = PostRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': <dynamic>[_pendingPostJson()],
            });
          },
          postHandler: (path, data) async {
            expect(path, contains('/posts/1/approve'));
            approveCalled = true;
            final approved = _pendingPostJson()
              ..['approval_status'] = 'approved';
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': approved,
            });
          },
        ),
      );

      await _pump(tester, repository);
      expect(find.text('Draft awaiting review'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
      await tester.pumpAndSettle();

      expect(approveCalled, isTrue);
      expect(find.text('Draft awaiting review'), findsNothing);
      expect(find.text('Post approved.'), findsOneWidget);
    },
  );

  testWidgets(
    'rejecting asks for confirmation, then calls the reject endpoint and removes the card',
    (tester) async {
      var rejectCalled = false;
      final repository = PostRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': <dynamic>[_pendingPostJson()],
            });
          },
          postHandler: (path, data) async {
            expect(path, contains('/posts/1/reject'));
            rejectCalled = true;
            final rejected = _pendingPostJson()
              ..['approval_status'] = 'rejected';
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': rejected,
            });
          },
        ),
      );

      await _pump(tester, repository);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Reject this post?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
      await tester.pumpAndSettle();

      expect(rejectCalled, isTrue);
      expect(find.text('Draft awaiting review'), findsNothing);
      expect(find.text('Post rejected.'), findsOneWidget);
    },
  );
}
