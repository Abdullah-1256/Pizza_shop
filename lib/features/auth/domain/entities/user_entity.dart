import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? phone;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? emailConfirmedAt;
  final DateTime? lastSignInAt;
  final Map<String, dynamic>? userMetadata;
  final Map<String, dynamic>? appMetadata;
  final bool isAnonymous;
  final String role;
  final String aud;

  const UserEntity({
    required this.id,
    this.email,
    this.name,
    this.photoUrl,
    this.phone,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.emailConfirmedAt,
    this.lastSignInAt,
    this.userMetadata,
    this.appMetadata,
    this.isAnonymous = false,
    this.role = 'authenticated',
    this.aud = 'authenticated',
  });

  factory UserEntity.fromSupabaseUser(supabase.User user) {
    return UserEntity(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['name'] as String?,
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      phone: user.phone,
      isEmailVerified: user.emailConfirmedAt != null,
      createdAt: user.createdAt != null
          ? DateTime.parse(user.createdAt!)
          : null,
      updatedAt: user.updatedAt != null
          ? DateTime.parse(user.updatedAt!)
          : null,
      emailConfirmedAt: user.emailConfirmedAt != null
          ? DateTime.parse(user.emailConfirmedAt!)
          : null,
      lastSignInAt: user.lastSignInAt != null
          ? DateTime.parse(user.lastSignInAt!)
          : null,
      userMetadata: user.userMetadata,
      appMetadata: user.appMetadata,
      isAnonymous: user.isAnonymous ?? false,
      role: user.role ?? 'authenticated',
      aud: user.aud ?? 'authenticated',
    );
  }

  static const empty = UserEntity(id: '');

  bool get isEmpty => this == UserEntity.empty;
  bool get isNotEmpty => this != UserEntity.empty;

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    phone,
    isEmailVerified,
    createdAt,
    updatedAt,
    emailConfirmedAt,
    lastSignInAt,
    userMetadata,
    appMetadata,
    isAnonymous,
    role,
    aud,
  ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? phone,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? emailConfirmedAt,
    DateTime? lastSignInAt,
    Map<String, dynamic>? userMetadata,
    Map<String, dynamic>? appMetadata,
    bool? isAnonymous,
    String? role,
    String? aud,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      userMetadata: userMetadata ?? this.userMetadata,
      appMetadata: appMetadata ?? this.appMetadata,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      role: role ?? this.role,
      aud: aud ?? this.aud,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phone': phone,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'emailConfirmedAt': emailConfirmedAt?.toIso8601String(),
      'lastSignInAt': lastSignInAt?.toIso8601String(),
      'userMetadata': userMetadata,
      'appMetadata': appMetadata,
      'isAnonymous': isAnonymous,
      'role': role,
      'aud': aud,
    };
  }
}
