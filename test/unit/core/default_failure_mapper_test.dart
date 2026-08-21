import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/base/failure_mapper.dart';
import 'package:smart_publisher/src/core/result/app_failure.dart';

DioException _dioException({required int statusCode, required dynamic data}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('DefaultFailureMapper', () {
    const mapper = DefaultFailureMapper();

    test(
      'surfaces the backend field-specific validation message instead of the generic fallback',
      () {
        final error = _dioException(
          statusCode: 422,
          data: <String, dynamic>{
            'message': 'Validation failed',
            'errors': <String, dynamic>{
              'email': <String>['The email has already been taken.'],
            },
          },
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Failed to add member',
        );

        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'The email has already been taken.');
      },
    );

    test(
      'a 422 exposes the full per-field errors map, not just the first message',
      () {
        final error = _dioException(
          statusCode: 422,
          data: <String, dynamic>{
            'message': 'Validation failed',
            'errors': <String, dynamic>{
              'title': <String>['The title field is required.'],
              'scheduled_at': <String>[
                'The scheduled at field must be a date after now.',
              ],
            },
          },
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Failed to schedule post',
        );

        expect(failure, isA<ValidationFailure>());
        final validationFailure = failure as ValidationFailure;
        expect(validationFailure.fieldErrors, <String, List<String>>{
          'title': ['The title field is required.'],
          'scheduled_at': ['The scheduled at field must be a date after now.'],
        });
      },
    );

    test(
      'a 422 with no errors object still classifies as ValidationFailure with a null fieldErrors map',
      () {
        final error = _dioException(
          statusCode: 422,
          data: <String, dynamic>{'message': 'Validation failed'},
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Failed to submit',
        );

        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).fieldErrors, isNull);
      },
    );

    test(
      'a real connection failure (no response at all) is still classified as NetworkFailure, not ValidationFailure',
      () {
        final requestOptions = RequestOptions(path: '/test');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Failed to load posts',
        );

        expect(failure, isA<NetworkFailure>());
      },
    );

    test(
      'surfaces the backend message for a 403 without leaking the internal error code',
      () {
        final error = _dioException(
          statusCode: 403,
          data: <String, dynamic>{
            'message':
                'You do not have permission to manage members in this organization.',
            'errors': <String, dynamic>{
              'code': <String>['unauthorized'],
            },
          },
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Failed to update member role',
        );

        expect(failure, isA<AuthorizationFailure>());
        expect(
          failure.message,
          'You do not have permission to manage members in this organization.',
        );
      },
    );

    test(
      'falls back to the caller-supplied message when the backend sent no body',
      () {
        final requestOptions = RequestOptions(path: '/test');
        final error = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Failed to load accounts',
        );

        expect(failure.message, 'Failed to load accounts');
      },
    );

    test(
      'classifies a 500 as ServerFailure using the real backend message',
      () {
        final error = _dioException(
          statusCode: 500,
          data: <String, dynamic>{'message': 'Internal server error'},
        );

        final failure = mapper.map(
          error,
          StackTrace.empty,
          fallbackMessage: 'Something went wrong',
        );

        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Internal server error');
      },
    );

    test(
      'a non-DioException, non-StateError error uses UnknownFailure with the fallback',
      () {
        final failure = mapper.map(
          Exception('boom'),
          StackTrace.empty,
          fallbackMessage: 'Unexpected failure',
        );

        expect(failure, isA<UnknownFailure>());
        expect(failure.message, 'Unexpected failure');
      },
    );
  });
}
