import '../../features/auth/domain/entities/account_entity.dart';
import '../../features/auth/domain/entities/social_page_entity.dart';
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
import 'social_pages_contract_v1.dart';

class BackendContractMapperV1 {
  const BackendContractMapperV1._();

  static PostRequestDtoV1 toPostRequest(PostEntity entity) {
    return PostRequestDtoV1(
      title: entity.title,
      content: entity.body,
      attachments: entity.attachments,
      platforms: entity.platforms,
      targetPageIds: entity.targetPageIds,
      scheduledAt: entity.scheduledAt,
      platformContent: entity.platformContent,
    );
  }

  static PostUpdateRequestDtoV1 toPostUpdateRequest(PostEntity entity) {
    return PostUpdateRequestDtoV1(
      title: entity.title,
      content: entity.body,
      targetPageIds: entity.targetPageIds,
      platformContent: entity.platformContent,
    );
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
      publishedAt: dto.publishedAt,
      aiImproved: false,
      hasMedia: dto.attachments.isNotEmpty,
      attachments: dto.attachments,
      platforms: dto.platforms,
      targetPageIds: dto.targetPageIds,
      platformContent: dto.platformContent,
      approvalStatus: dto.approvalStatus,
      approvalRequestedAction: dto.approvalRequestedAction,
      approvalNote: dto.approvalNote,
      approvedByName: dto.approvedByName,
      authorName: dto.authorName,
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

  static MediaEntity toMediaEntity(MediaResponseDtoV1 dto) {
    return MediaEntity(
      id: dto.id,
      postId: dto.postId,
      url: dto.url,
      mimeType: dto.mimeType,
      sizeInBytes: dto.sizeInBytes,
      isCompressed: dto.isCompressed,
      thumbnailUrl: dto.thumbnailUrl,
      collection: dto.collection,
      tags: dto.tags,
      createdAt: dto.createdAt,
      isDuplicateOfId: dto.duplicateOfId,
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

  static AccountEntity toAccountEntity(SocialAccountResponseDtoV1 dto) {
    return AccountEntity(
      id: dto.id,
      remoteId: dto.id,
      name: dto.accountName?.isNotEmpty == true
          ? dto.accountName!
          : dto.provider,
      platform: dto.provider,
      status: dto.status,
      hasRefreshToken: dto.hasRefreshToken,
      permissions: dto.scopes,
      discoveryMode: dto.discoveryMode,
      metadata: dto.metadata,
      tokenExpiresAt: dto.tokenExpiresAt,
      lastSyncedAt: dto.lastSyncedAt,
      lastPublishedAt: dto.lastPublishedAt,
    );
  }

  static SocialPageEntity toSocialPageEntity(SocialPageResponseDtoV1 dto) {
    return SocialPageEntity(
      id: dto.id,
      socialAccountId: dto.socialAccountId,
      pageId: dto.pageId,
      kind: dto.kind,
      name: dto.name?.isNotEmpty == true ? dto.name! : dto.pageId,
      username: dto.username,
      pictureUrl: dto.pictureUrl,
      canPublish: dto.canPublish,
      isSelected: dto.isSelected,
      status: dto.status,
      memberCount: dto.memberCount,
      lastSyncedAt: dto.lastSyncedAt,
      lastVerifiedAt: dto.lastVerifiedAt,
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
