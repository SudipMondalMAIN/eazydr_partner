class Facility {
  final String id;
  final String name;
  final String type;
  final String address;
  final String city;
  final String? phone;
  final String? photoUrl;
  final bool isActive;

  Facility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    this.phone,
    this.photoUrl,
    this.isActive = true,
  });

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        type: json['type'] ?? json['facility_type'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        phone: json['phone'],
        photoUrl: json['photo_url'],
        isActive: json['is_active'] ?? true,
      );
}
