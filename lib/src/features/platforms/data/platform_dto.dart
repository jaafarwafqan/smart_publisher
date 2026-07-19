class PlatformDto {
  const PlatformDto({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
  });

  final String id;
  final String name;
  final String type;
  final bool isConnected;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'isConnected': isConnected,
  };
}
