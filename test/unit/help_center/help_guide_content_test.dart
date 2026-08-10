import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/route_names.dart';
import 'package:smart_publisher/src/features/help_center/content/about_content.dart';
import 'package:smart_publisher/src/features/help_center/content/faq_and_troubleshooting_content.dart';
import 'package:smart_publisher/src/features/help_center/content/user_guide_content.dart';
import 'package:smart_publisher/src/features/help_center/domain/models/platform_help_status.dart';

/// Every route a guide article is allowed to jump to — anything outside
/// this set means a typo'd path that would 404 inside GoRouter at runtime.
const _knownRoutes = <String>{
  RouteNames.organizationsPath,
  RouteNames.postsCreatePath,
  RouteNames.calendarPath,
  RouteNames.mediaLibraryPath,
  RouteNames.analyticsPath,
  RouteNames.notificationsPath,
  RouteNames.organizationMembersPath,
  RouteNames.settingsPath,
  RouteNames.helpCenterPath,
  RouteNames.userGuidePath,
};

/// Patterns that must never appear in author-written guide content — a
/// regression net, not a claim that a real secret was ever committed here.
const _forbiddenPatterns = <String>[
  'access_token=',
  'bot_token=',
  'client_secret=',
  'app_secret=',
  'Bearer ey',
];

void main() {
  group('User guide content integrity', () {
    test('every article action route points to a real, known route', () {
      for (final section in buildUserGuideSections()) {
        for (final article in section.articles) {
          if (article.actionRoute == null) {
            continue;
          }
          expect(
            _knownRoutes.contains(article.actionRoute),
            isTrue,
            reason: '${section.id}/${article.id} -> ${article.actionRoute}',
          );
          expect(
            article.actionLabel,
            isNotNull,
            reason: '${section.id}/${article.id}',
          );
        }
      }
    });

    test(
      'no section/article/FAQ/troubleshooting text contains a token, secret, or key value',
      () {
        final allText = StringBuffer()
          ..writeln(AboutContent.systemDefinition)
          ..writeAll(AboutContent.goals, '\n')
          ..writeAll(AboutContent.realFeatures, '\n')
          ..writeAll(AboutContent.security, '\n');

        for (final section in buildUserGuideSections()) {
          allText.writeln(section.title);
          for (final article in section.articles) {
            allText
              ..writeln(article.title)
              ..writeln(article.summary)
              ..writeAll(article.notes, '\n');
            for (final step in article.steps) {
              allText.writeln(step.text);
            }
            for (final faq in article.faqs) {
              allText
                ..writeln(faq.question)
                ..writeln(faq.answer);
            }
          }
        }
        for (final faq in buildGlobalFaqs()) {
          allText
            ..writeln(faq.question)
            ..writeln(faq.answer);
        }
        for (final item in buildTroubleshootingItems()) {
          allText
            ..writeln(item.symptom)
            ..writeln(item.fix);
        }

        final combined = allText.toString().toLowerCase();
        for (final pattern in _forbiddenPatterns) {
          expect(
            combined.contains(pattern.toLowerCase()),
            isFalse,
            reason: pattern,
          );
        }
      },
    );

    test(
      'the role permission table only ever grants what the backend actually grants',
      () {
        // Cross-checked by hand against App\Enums\OrganizationRole::permissions()
        // on 2026-08-10 — this just guards against silent future drift.
        final rows = buildRolePermissionRows();
        expect(rows, isNotEmpty);
        for (final row in rows) {
          expect(row.grantedTo, isNotEmpty, reason: row.action);
          for (final role in row.grantedTo) {
            expect(
              <String>[
                'viewer',
                'editor',
                'manager',
                'admin',
                'owner',
              ].contains(role),
              isTrue,
              reason: '${row.action}: unknown role "$role"',
            );
          }
        }
        // Owner-only actions must never also be granted to a lower role.
        final ownershipRow = rows.firstWhere(
          (row) => row.action.contains('نقل ملكية'),
        );
        expect(ownershipRow.grantedTo, <String>['owner']);
      },
    );
  });

  group('Platform readiness classification', () {
    test('WhatsApp is partial, never available-beta or fully mock', () {
      final statuses = platformHelpStatuses();
      final whatsapp = statuses.firstWhere(
        (status) => status.platformId == 'whatsapp',
      );

      expect(whatsapp.readiness, PlatformReadiness.partial);
      expect(whatsapp.canPublish, isFalse);
      expect(whatsapp.canConnect, isFalse);
    });

    test('only Facebook and Telegram are available-beta', () {
      final availableBeta = platformHelpStatuses()
          .where(
            (status) => status.readiness == PlatformReadiness.availableBeta,
          )
          .map((status) => status.platformId)
          .toSet();

      expect(availableBeta, <String>{'facebook', 'telegram'});
    });

    test('mock-backed platforms never claim to support publishing', () {
      for (final status in platformHelpStatuses()) {
        if (status.readiness == PlatformReadiness.comingSoonMock) {
          expect(status.canPublish, isFalse, reason: status.platformId);
          expect(status.canConnect, isFalse, reason: status.platformId);
        }
      }
    });
  });
}
