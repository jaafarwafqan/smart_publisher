import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/backend_contracts/v1/analytics_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/calendar_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/posts_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/settings_contract_v1.dart';
import 'package:smart_publisher/src/backend_contracts/v1/users_contract_v1.dart';

void main() {
  group('Contract - Extended v1', () {
    test('UserResponseDtoV1 parses mixed types', () {
      final dto = UserResponseDtoV1.fromJson(<String, dynamic>{
        'id': 99,
        'name': 'Admin',
        'email': 'admin@example.com',
        'role': 'admin',
        'is_active': '1',
      });

      expect(dto.id, '99');
      expect(dto.isActive, isTrue);
      expect(dto.role, 'admin');
    });

    test('CalendarEntryResponseDtoV1 parses schedule and platforms', () {
      final dto = CalendarEntryResponseDtoV1.fromJson(<String, dynamic>{
        'post_id': 10,
        'title': 'Queued post',
        'status': 'scheduled',
        'platforms': <dynamic>['facebook', 15],
        'scheduled_at': '2026-08-01T09:00:00Z',
      });

      expect(dto.postId, '10');
      expect(dto.platforms, <String>['facebook', '15']);
      expect(dto.scheduledAt, isNotNull);
    });

    test('SettingsResponseDtoV1 parses numeric and bool-like values', () {
      final dto = SettingsResponseDtoV1.fromJson(<String, dynamic>{
        'timezone': 'Africa/Casablanca',
        'locale': 'ar',
        'notifications_enabled': 'true',
        'daily_digest_hour': '7',
      });

      expect(dto.notificationsEnabled, isTrue);
      expect(dto.dailyDigestHour, 7);
    });

    test('PostResponseDtoV1 parses scalar values safely', () {
      final dto = PostResponseDtoV1.fromJson(<String, dynamic>{
        'id': 123,
        'title': 'Title',
        'content': 'Body',
        'status': 'draft',
      });

      expect(dto.id, '123');
      expect(dto.title, 'Title');
    });

    test('PostAnalyticsResponseDtoV1 parses numeric strings', () {
      final dto = PostAnalyticsResponseDtoV1.fromJson(<String, dynamic>{
        'post_id': 77,
        'impressions': '1000',
        'clicks': '11',
        'shares': 2.0,
        'reactions': '9',
        'status': 'published',
      });

      expect(dto.postId, '77');
      expect(dto.impressions, 1000);
      expect(dto.clicks, 11);
      expect(dto.shares, 2);
      expect(dto.reactions, 9);
    });
  });
}
