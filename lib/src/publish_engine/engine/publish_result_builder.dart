import '../../platforms/core/publish_result.dart';

class PublishResultBuilder {
  const PublishResultBuilder();

  PublishResult buildSuccess(String message, {String? externalId}) {
    return PublishResult(
      success: true,
      message: message,
      externalId: externalId,
    );
  }

  PublishResult buildFailure(String message, {String? errorCode}) {
    return PublishResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}
