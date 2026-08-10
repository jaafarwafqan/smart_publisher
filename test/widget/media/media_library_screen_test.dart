import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/media/domain/repositories/media_repository.dart';
import 'package:smart_publisher/src/features/media/presentation/pages/media_library_screen.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/core/base/pagination.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';
import '../../helpers/organization_role_fixtures.dart';

class _FailingMediaRepository extends MediaRepository {
  const _FailingMediaRepository();

  @override
  Future<AppResult<List<MediaEntity>>> getMediaLibrary({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
  }) async => const Failure<List<MediaEntity>>('Network unreachable');

  @override
  Future<AppResult<PaginatedResult<MediaEntity>>> getMediaLibraryPage({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
    int page = 1,
  }) async =>
      const Failure<PaginatedResult<MediaEntity>>('Network unreachable');

  @override
  Future<AppResult<MediaEntity>> uploadMedia(MediaEntity media) async =>
      throw UnimplementedError();

  @override
  Future<AppResult<MediaEntity>> compressMedia(MediaEntity media) async =>
      throw UnimplementedError();

  @override
  Future<AppResult<void>> deleteMedia(String id) async =>
      throw UnimplementedError();

  @override
  Future<AppResult<void>> attachMediaToPost({
    required String mediaId,
    required String postId,
  }) async => throw UnimplementedError();
}

final _ownerAccess = OrganizationAccessState.active(
  memberships: <OrganizationEntity>[
    OrganizationEntity(
      id: 1,
      name: 'Owner Organization',
      slug: 'owner-organization',
      role: 'owner',
      isCurrent: true,
      permissions: permissionsForRole('owner'),
    ),
  ],
  currentOrganization: OrganizationEntity(
    id: 1,
    name: 'Owner Organization',
    slug: 'owner-organization',
    role: 'owner',
    isCurrent: true,
    permissions: permissionsForRole('owner'),
  ),
);

final _viewerAccess = OrganizationAccessState.active(
  memberships: <OrganizationEntity>[
    OrganizationEntity(
      id: 1,
      name: 'Viewer Organization',
      slug: 'viewer-organization',
      role: 'viewer',
      isCurrent: true,
      permissions: permissionsForRole('viewer'),
    ),
  ],
  currentOrganization: OrganizationEntity(
    id: 1,
    name: 'Viewer Organization',
    slug: 'viewer-organization',
    role: 'viewer',
    isCurrent: true,
    permissions: permissionsForRole('viewer'),
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  OrganizationAccessState? organizationAccess,
  MediaRepository? mediaRepositoryOverride,
}) async {
  final mediaRepository =
      mediaRepositoryOverride ??
      MediaRepositoryImpl(
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
                    'post_id': null,
                    'url': 'https://cdn.example.com/media/photo.jpg',
                    'thumbnail_path':
                        'https://cdn.example.com/media/photo_thumb.jpg',
                    'mime_type': 'image/jpeg',
                    'size_in_bytes': 2048,
                    'collection': 'default',
                    'tags': <String>['beach', 'vacation'],
                    'created_at': '2026-07-26T10:00:00Z',
                  },
                  <String, dynamic>{
                    'id': '2',
                    'post_id': null,
                    'url': 'https://cdn.example.com/media/clip.mp4',
                    'mime_type': 'video/mp4',
                    'size_in_bytes': 500000,
                    'collection': 'default',
                    'tags': <String>[],
                    'created_at': '2026-07-25T10:00:00Z',
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
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
        currentOrganizationAccessProvider.overrideWith(
          (_) async => organizationAccess ?? _ownerAccess,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: MediaLibraryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders real media items with tag chips, not fabricated post attachments',
    (tester) async {
      await _pump(tester);

      expect(find.text('beach'), findsOneWidget);
      expect(find.text('vacation'), findsOneWidget);
      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.text('clip.mp4'), findsOneWidget);
    },
  );

  testWidgets('Compress is disabled for video, enabled for images', (
    tester,
  ) async {
    await _pump(tester);

    final compressButtons = find.widgetWithText(OutlinedButton, 'Compress');
    expect(compressButtons, findsNWidgets(2));

    final imageButton = tester.widget<OutlinedButton>(compressButtons.at(0));
    final videoButton = tester.widget<OutlinedButton>(compressButtons.at(1));

    expect(imageButton.onPressed, isNotNull);
    expect(videoButton.onPressed, isNull);
  });

  testWidgets('Reuse in Post reports when no posts are available', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Reuse in Post').first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No posts available to attach this media to.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a viewer without update/delete permissions sees neither Compress nor Delete',
    (tester) async {
      await _pump(tester, organizationAccess: _viewerAccess);

      expect(find.widgetWithText(OutlinedButton, 'Compress'), findsNothing);
      expect(find.byTooltip('Delete media asset'), findsNothing);
      // Still allowed: reusing existing media in a new post isn't a
      // destructive action on the media itself.
      expect(
        find.widgetWithText(OutlinedButton, 'Reuse in Post'),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'shows an error and retry instead of rendering a failed fetch as empty',
    (tester) async {
      await _pump(
        tester,
        mediaRepositoryOverride: const _FailingMediaRepository(),
      );

      expect(find.text('Network unreachable'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'a second backend page of media is reachable via Load more, not silently capped',
    (tester) async {
      Map<String, dynamic> pageResponse(int page, int lastPage) {
        return <String, dynamic>{
          'success': true,
          'data': <dynamic>[
            <String, dynamic>{
              'id': 'm$page',
              'post_id': null,
              'url': 'https://cdn.example.com/media/page$page.jpg',
              'mime_type': 'image/jpeg',
              'size_in_bytes': 1024,
              'collection': 'default',
              'tags': <String>[],
              'created_at': '2026-07-26T10:00:00Z',
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

      final mediaRepository = MediaRepositoryImpl(
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
            mediaRepositoryProvider.overrideWithValue(mediaRepository),
            postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
            currentOrganizationAccessProvider.overrideWith(
              (_) async => _ownerAccess,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: MediaLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('page1.jpg'), findsOneWidget);
      expect(find.text('page2.jpg'), findsNothing);

      final loadMoreButton = find.widgetWithText(OutlinedButton, 'Load more');
      expect(loadMoreButton, findsOneWidget);

      await tester.tap(loadMoreButton);
      await tester.pumpAndSettle();

      expect(find.text('page1.jpg'), findsOneWidget);
      expect(find.text('page2.jpg'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Load more'), findsNothing);
    },
  );
}
