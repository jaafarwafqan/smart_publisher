import 'failure_mapper.dart';
import '../logger/logger_service.dart';
import '../result/app_result.dart';
import 'pagination.dart';
import 'transaction.dart';

abstract class BaseRepository<T> {
  const BaseRepository({
    this.loggerValue,
    this.failureMapperValue,
    this.transactionRunnerValue,
  });

  final LoggerService? loggerValue;
  final FailureMapper? failureMapperValue;
  final TransactionRunner? transactionRunnerValue;

  LoggerService get logger => loggerValue ?? _fallbackLogger;
  FailureMapper get failureMapper =>
      failureMapperValue ?? const DefaultFailureMapper();
  TransactionRunner get transactionRunner =>
      transactionRunnerValue ?? const NoopTransactionRunner();

  static final LoggerService _fallbackLogger = _FallbackLogger();
  static const RepositoryLoggerHooks _defaultLoggerHooks =
      RepositoryLoggerHooks();

  Future<AppResult<R>> execute<R>(
    Future<R> Function() action, {
    required String operation,
    String fallbackMessage = 'Repository operation failed',
    RepositoryLoggerHooks hooks = _defaultLoggerHooks,
    String? cacheWriteKey,
    Future<void> Function(R data)? cacheWriter,
  }) async {
    hooks.onBefore?.call(operation, logger);
    try {
      final result = await action();

      if (cacheWriter != null && cacheWriteKey != null) {
        if (result is T) {
          await beforeCacheWrite(cacheWriteKey, result);
        }
        await cacheWriter(result);
      }

      hooks.onSuccess?.call(operation, logger);
      return Success<R>(result, message: operation);
    } catch (error, stackTrace) {
      final failure = mapFailure(
        error,
        stackTrace,
        fallbackMessage: fallbackMessage,
      );
      hooks.onError?.call(operation, logger, error, stackTrace);
      logger.error(
        'Repository operation failed: $operation',
        error,
        stackTrace,
      );
      return Failure<R>.fromFailure(failure);
    }
  }

  Future<AppResult<List<R>>> executeList<R>(
    Future<List<R>> Function() action, {
    required String operation,
    String fallbackMessage = 'Repository list operation failed',
    RepositoryLoggerHooks hooks = _defaultLoggerHooks,
  }) async {
    hooks.onBefore?.call(operation, logger);
    try {
      final result = await action();
      hooks.onSuccess?.call(operation, logger);
      return Success<List<R>>(result, message: operation);
    } catch (error, stackTrace) {
      final failure = mapFailure(
        error,
        stackTrace,
        fallbackMessage: fallbackMessage,
      );
      hooks.onError?.call(operation, logger, error, stackTrace);
      logger.error(
        'Repository list operation failed: $operation',
        error,
        stackTrace,
      );
      return Failure<List<R>>.fromFailure(failure);
    }
  }

  Future<AppResult<R>> executeTransaction<R>(
    Future<R> Function() action, {
    required String operation,
    String fallbackMessage = 'Repository transaction failed',
  }) {
    return execute(
      () => transactionRunner.runInTransaction(action),
      operation: operation,
      fallbackMessage: fallbackMessage,
    );
  }

  AppFailure mapFailure(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    return failureMapper.map(
      error,
      stackTrace,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<bool> isNetworkAvailable() async {
    return true;
  }

  Future<void> beforeCacheWrite(String key, T data) async {}

  Future<void> afterCacheRead(String key, T data) async {}

  Future<void> onCacheMiss(String key) async {}

  PaginatedResult<T> paginateList(
    List<T> items, {
    required PaginationQuery query,
  }) {
    if (query.page < 1 || query.pageSize < 1) {
      return PaginatedResult<T>(
        items: <T>[],
        page: query.page,
        pageSize: query.pageSize,
        totalCount: items.length,
      );
    }

    final start = (query.page - 1) * query.pageSize;
    if (start >= items.length) {
      return PaginatedResult<T>(
        items: <T>[],
        page: query.page,
        pageSize: query.pageSize,
        totalCount: items.length,
      );
    }

    final end = start + query.pageSize;
    final pagedItems = items.sublist(
      start,
      end > items.length ? items.length : end,
    );
    return PaginatedResult<T>(
      items: pagedItems,
      page: query.page,
      pageSize: query.pageSize,
      totalCount: items.length,
    );
  }
}

class RepositoryLoggerHooks {
  const RepositoryLoggerHooks({this.onBefore, this.onSuccess, this.onError});

  final void Function(String operation, LoggerService logger)? onBefore;
  final void Function(String operation, LoggerService logger)? onSuccess;
  final void Function(
    String operation,
    LoggerService logger,
    Object error,
    StackTrace stackTrace,
  )?
  onError;
}

class _FallbackLogger implements LoggerService {
  const _FallbackLogger();

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}
