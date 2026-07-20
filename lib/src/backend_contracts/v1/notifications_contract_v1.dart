class NotificationResponseDtoV1 {
  const NotificationResponseDtoV1({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;

  factory NotificationResponseDtoV1.fromJson(Map<String, dynamic> json) {
    final readValue = json.containsKey('is_read')
        ? json['is_read']
        : json['read'];
    return NotificationResponseDtoV1(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      isRead: (readValue ?? false) as bool,
    );
  }
}
