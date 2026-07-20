enum PublishTargetCategory { social, messaging, professional }

class PublishTarget {
  const PublishTarget({required this.category, required this.destinationKey});

  final PublishTargetCategory category;
  final String destinationKey;
}
