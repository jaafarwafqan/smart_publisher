import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/platform_administration/data/platform_admin_repository.dart';

import '../../helpers/fake_network_client.dart';

/// Prepaid-billing model (2026-08-21) — the manual grant/extend/revert/trial
/// side of BillingPeriodGrantService, reachable from the platform-admin
/// organization detail screen.
void main() {
  Response<dynamic> subscriptionResponse(String path) => Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'organization_id': 7,
        'plan_id': 3,
        'status': 'active',
        'current_period_start': '2026-08-21T00:00:00Z',
        'current_period_end': '2027-02-21T00:00:00Z',
        'trial_ends_at': null,
        'provider_subscription_id': null,
        'granted_by_user_id': 1,
        'granted_reason': 'Annual sponsorship — comped access.',
      },
    },
  );

  group('PlatformAdminRepository.grantSubscription', () {
    test('POSTs plan_id/months/reason to the real endpoint', () async {
      String? postedPath;
      Map<String, dynamic>? postedData;
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          postHandler: (path, data) async {
            postedPath = path;
            postedData = data as Map<String, dynamic>;
            return subscriptionResponse(path);
          },
        ),
      );

      final subscription = await repository.grantSubscription(
        organizationId: 7,
        planId: 3,
        months: 6,
        reason: 'Annual sponsorship — comped access.',
      );

      expect(postedPath, contains('/admin/organizations/7/subscription'));
      expect(postedData, <String, dynamic>{
        'plan_id': 3,
        'months': 6,
        'reason': 'Annual sponsorship — comped access.',
      });
      expect(subscription.planId, 3);
      expect(subscription.status, 'active');
      expect(subscription.isManuallyGranted, isTrue);
    });

    test(
      'surfaces the backend\'s validation error for a missing reason',
      () async {
        final repository = PlatformAdminRepository(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              throw DioException(
                requestOptions: RequestOptions(path: path),
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                  statusCode: 422,
                  data: <String, dynamic>{
                    'message': 'Validation failed',
                    'errors': <String, dynamic>{
                      'reason': ['The reason field is required.'],
                    },
                  },
                ),
                type: DioExceptionType.badResponse,
              );
            },
          ),
        );

        await expectLater(
          repository.grantSubscription(
            organizationId: 7,
            planId: 3,
            months: 1,
            reason: '',
          ),
          throwsA(isA<PlatformAdminException>()),
        );
      },
    );
  });

  group('PlatformAdminRepository.extendSubscription', () {
    test('POSTs only the provided day/month fields', () async {
      Map<String, dynamic>? postedData;
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          postHandler: (path, data) async {
            postedData = data as Map<String, dynamic>;
            return subscriptionResponse(path);
          },
        ),
      );

      await repository.extendSubscription(
        organizationId: 7,
        days: 30,
        reason: 'Goodwill extension.',
      );

      expect(postedData, <String, dynamic>{
        'days': 30,
        'reason': 'Goodwill extension.',
      });
    });
  });

  group('PlatformAdminRepository.revertSubscriptionToFree', () {
    test('DELETEs with the reason in the body', () async {
      String? deletedPath;
      Map<String, dynamic>? deletedData;
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          deleteHandler: (path, data) async {
            deletedPath = path;
            deletedData = data as Map<String, dynamic>;
            return subscriptionResponse(path);
          },
        ),
      );

      await repository.revertSubscriptionToFree(
        organizationId: 7,
        reason: 'Trial ended without a paid conversion.',
      );

      expect(deletedPath, contains('/admin/organizations/7/subscription'));
      expect(deletedData, <String, dynamic>{
        'reason': 'Trial ended without a paid conversion.',
      });
    });
  });

  group('PlatformAdminRepository.grantSubscriptionTrial', () {
    test('POSTs days/reason to the trial endpoint, no plan_id', () async {
      String? postedPath;
      Map<String, dynamic>? postedData;
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          postHandler: (path, data) async {
            postedPath = path;
            postedData = data as Map<String, dynamic>;
            return subscriptionResponse(path);
          },
        ),
      );

      await repository.grantSubscriptionTrial(
        organizationId: 7,
        days: 14,
        reason: 'Evaluating before a paid commitment.',
      );

      expect(postedPath, contains('/admin/organizations/7/subscription/trial'));
      expect(postedData, <String, dynamic>{
        'days': 14,
        'reason': 'Evaluating before a paid commitment.',
      });
      expect(postedData!.containsKey('plan_id'), isFalse);
    });
  });

  group('PlatformAdminRepository.getPlans', () {
    test('parses the global plan list', () async {
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          getHandler: (path) async => Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <dynamic>[
                <String, dynamic>{
                  'id': 3,
                  'name': 'Enterprise',
                  'price_cents': 500000,
                  'currency': 'IQD',
                },
              ],
            },
          ),
        ),
      );

      final plans = await repository.getPlans();

      expect(plans, hasLength(1));
      expect(plans.single.id, 3);
      expect(plans.single.name, 'Enterprise');
      expect(plans.single.currency, 'IQD');
    });
  });
}
