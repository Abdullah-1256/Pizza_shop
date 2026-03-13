class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? profileImageUrl;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.profileImageUrl,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? profileImageUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profile_image_url': profileImageUrl,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}
