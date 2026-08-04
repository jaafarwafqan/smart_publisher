enum PublishTargetCategory { social, messaging, professional }

class PublishTarget {
  const PublishTarget({
    required this.category,
    required this.destinationKey,
    required this.socialPageId,
    this.pageLabel,
  });

  final PublishTargetCategory category;
  final String destinationKey;

  /// The backend `social_pages.id` this target actually publishes to — a
  /// platform alone is never enough to know which Page/Channel/Business
  /// Account receives the post.
  final String socialPageId;

  /// Display-only label (e.g. "College of Nursing"), for previews/logging.
  final String? pageLabel;
}
