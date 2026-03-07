enum DeviceStatus { online, offline }

class DeviceEntity {
  final String id;
  final String name;
  final DeviceStatus status;

  const DeviceEntity({
    required this.id,
    required this.name,
    required this.status,
  });
}
