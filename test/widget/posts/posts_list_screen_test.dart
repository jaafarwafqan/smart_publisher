import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/presentation/pages/posts_list_screen.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

final _ownerAccess = OrganizationAccessState.active(
  memberships: const <OrganizationEntity>[
    OrganizationEntity(
      id: 1,
      name: 'Owner Organization',
      slug: 'owner-organization',
      role: 'owner',
      isCurrent: true,
    ),
  ],
  currentOrganization: const OrganizationEntity(
    id: 1,
    name: 'Owner Organization',
    slug: 'owner-organization',
    role: 'owner',
    isCurrent: true,
  ),
);

final _viewerAccess = OrganizationAccessState.active(
  memberships: const <OrganizationEntity>[
    OrganizationEntity(
      id: 1,
      name: 'Viewer Organization',
      slug: 'viewer-organization',
      role: 'viewer',
      isCurrent: true,
    ),
  ],
  currentOrganization: const OrganizationEntity(
    id: 1,
    name: 'Viewer Organization',
    slug: 'viewer-organization',
    role: 'viewer',
    isCurrent: true,
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  OrganizationAccessState? organizationAccess,
}) async {
  final postRepository = PostRepositoryImpl(
    networkClient: FakeNetworkClient(
      getHandler: (path) async {
        return Response<dynamic>(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'data': <dynamic>[
              <String, dynamic>{
                'id': '1',
                'title': 'Failed campaign post',
                'content': 'Body',
                'status': 'failed',
              },
              <String, dynamic>{
                'id': '2',
                'title': 'Mid-flight post',
                'content': 'Body',
                'status': 'publishing',
              },
            ],
          },
        );
      },
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        postRepositoryProvider.overrideWithValue(postRepository),
        currentOrganizationAccessProvider.overrideWith(
          (_) async => organizationAccess ?? _ownerAccess,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: PostsListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'post lifecycle statuses render as localized labels, not raw backend strings',
    (tester) async {
      await _pump(tester);

      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Publishing'), findsOneWidget);
      // The raw backend strings must never leak through uppercased.
      expect(find.text('FAILED'), findsNothing);
      expect(find.text('PUBLISHING'), findsNothing);
    },
  );

  testWidgets('an owner with update permissions sees the edit action', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byTooltip('Edit draft'), findsNWidgets(2));
  });

  testWidgets('a viewer without update permissions sees no edit action', (
    tester,
  ) async {
    await _pump(tester, organizationAccess: _viewerAccess);

    expect(find.byTooltip('Edit draft'), findsNothing);
  });

  testWidgets(
    'a second backend page of posts is reachable via Load more, not silently capped',
    (tester) async {
      Map<String, dynamic> pageResponse(int page, int lastPage) {
        return <String, dynamic>{
          'success': true,
          'data': <dynamic>[
            <String, dynamic>{
              'id': 'p$page',
              'title': 'Post from page $page',
              'content': 'Body',
              'status': 'draft',
            },
          ],
          'meta': <String, dynamic>{
            'current_page': page,
            'last_page': lastPage,
            'per_page': 1,
            'total': lastPage,
          },
        };
      }

      final postRepository = PostRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            final requestedPage = path.contains('page=2') ? 2 : 1;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: pageResponse(requestedPage, 2),
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            postRepositoryProvider.overrideWithValue(postRepository),
            currentOrganizationAccessProvider.overrideWith(
              (_) async => _ownerAccess,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: PostsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Post from page 1'), findsOneWidget);
      expect(find.text('Post from page 2'), findsNothing);

      final loadMoreButton = find.widgetWithText(OutlinedButton, 'Load more');
      expect(loadMoreButton, findsOneWidget);

      await tester.tap(loadMoreButton);
      await tester.pumpAndSettle();

      expect(find.text('Post from page 1'), findsOneWidget);
      expect(find.text('Post from page 2'), findsOneWidget);
      // Page 2 of 2 — no further pages, so the button disappears.
      expect(find.widgetWithText(OutlinedButton, 'Load more'), findsNothing);
    },
  );
}
