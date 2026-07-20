import '../../features/auth/domain/entities/account_entity.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/posts/domain/entities/media_entity.dart';
import '../../features/posts/domain/entities/post_entity.dart';
import '../../features/publish/domain/entities/publish_job_entity.dart';
import 'accounts_contract_v1.dart';
import 'analytics_contract_v1.dart';
import 'auth_contract_v1.dart';
import 'media_contract_v1.dart';
import 'notifications_contract_v1.dart';
import 'posts_contract_v1.dart';
import 'publish_contract_v1.dart';

class BackendContractMapperV1 {
  const BackendContractMapperV1._();

  static PostRequestDtoV1 toPostRequest(PostEntity entity) {
    return PostRequestDtoV1(
      title: entity.title,
      content: entity.body,
      attachments: entity.attachments,
      platforms: entity.platforms,
      scheduledAt: entity.scheduledAt,
    );
  }

  static PostUpdateRequestDtoV1 toPostUpdateRequest(PostEntity entity) {
    return PostUpdateRequestDtoV1(title: entity.title, content: entity.body);
  }

  static PostEntity toPostEntity(PostResponseDtoV1 dto) {
    return PostEntity(
      id: dto.id,
      title: dto.title,
      body: dto.content,
      status: dto.status,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      scheduledAt: dto.scheduledAt,
      aiImproved: false,
      hasMedia: dto.attachments.isNotEmpty,
      attachments: dto.attachments,
      platforms: dto.platforms,
    );
  }

  static MediaUploadRequestDtoV1 toMediaUploadRequest(MediaEntity entity) {
    final fileName = _extractFileName(entity.url);
    return MediaUploadRequestDtoV1(
      postId: entity.postId,
      fileName: fileName,
      mimeType: entity.mimeType,
      fileSize: entity.sizeInBytes,
    );
  }

  static MediaCompressRequestDtoV1 toMediaCompressRequest(MediaEntity entity) {
    return MediaCompressRequestDtoV1(mediaId: entity.id);
  }

  static MediaEntity toMediaEntity(MediaResponseDtoV1 dto) {
    return MediaEntity(
      id: dto.id,
      postId: dto.postId,
      url: dto.url,
      mimeType: dto.mimeType,
      sizeInBytes: dto.sizeInBytes,
      isCompressed: dto.isCompressed,
    );
  }

  static PublishJobEntity toPublishJobEntity(PublishJobResponseDtoV1 dto) {
    return PublishJobEntity(
      id: dto.id,
      postId: dto.postId,
      status: _toPublishStatus(dto.status),
      retryCount: dto.retryCount,
      progress: dto.progress,
    );
  }

  static PublishStatus _toPublishStatus(String status) {
    switch (status) {
      case 'publishing':
        return PublishStatus.publishing;
      case 'published':
        return PublishStatus.published;
      case 'failed':
        return PublishStatus.failed;
      case 'retrying':
        return PublishStatus.retrying;
      case 'queued':
      default:
        return PublishStatus.queued;
    }
  }

  static AccountEntity toAccountEntity(AccountResponseDtoV1 dto) {
    return AccountEntity(
      id: dto.id,
      name: dto.name,
      platform: dto.platform,
      isConnected: dto.isConnected,
      avatarUrl: dto.avatarUrl,
      status: dto.isConnected ? 'Connected' : 'Disconnected',
      permissions: dto.permissions,
    );
  }

  static UserEntity toUserEntity(AuthUserDtoV1 dto) {
    return UserEntity(id: dto.id, name: dto.name, email: dto.email);
  }

  static NotificationEntity toNotificationEntity(
    NotificationResponseDtoV1 dto,
  ) {
    return NotificationEntity(
      id: dto.id,
      title: dto.title,
      body: dto.body,
      isRead: dto.isRead,
    );
  }

  static Map<String, dynamic> toAnalyticsMap(PostAnalyticsResponseDtoV1 dto) {
    return dto.toJson();
  }

  static String _extractFileName(String url) {
    if (url.isEmpty) {
      return 'upload.bin';
    }
    final lastSlash = url.lastIndexOf('/');
    if (lastSlash == -1 || lastSlash == url.length - 1) {
      return url;
    }
    return url.substring(lastSlash + 1);
  }
}
