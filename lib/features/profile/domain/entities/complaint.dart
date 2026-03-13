import 'package:flutter/material.dart';

enum ComplaintStatus { pending, in_review, resolved, closed }

enum ComplaintType {
  order_issue,
  food_quality,
  delivery_delay,
  wrong_order,
  payment_issue,
  app_issue,
  other,
}

class Complaint {
  final String id;
  final String userId;
  final String userEmail;
  final ComplaintType type;
  final String subject;
  final String message;
  final ComplaintStatus status;
  final String? orderId;
  final String? adminResponse;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const Complaint({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    this.orderId,
    this.adminResponse,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  String get statusDisplayName {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.in_review:
        return 'In Review';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case ComplaintType.order_issue:
        return 'Order Issue';
      case ComplaintType.food_quality:
        return 'Food Quality';
      case ComplaintType.delivery_delay:
        return 'Delivery Delay';
      case ComplaintType.wrong_order:
        return 'Wrong Order';
      case ComplaintType.payment_issue:
        return 'Payment Issue';
      case ComplaintType.app_issue:
        return 'App Issue';
      case ComplaintType.other:
        return 'Other';
    }
  }

  Color get statusColor {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.in_review:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  Complaint copyWith({
    String? id,
    String? userId,
    String? userEmail,
    ComplaintType? type,
    String? subject,
    String? message,
    ComplaintStatus? status,
    String? orderId,
    String? adminResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      adminResponse: adminResponse ?? this.adminResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'type': type.name,
      'subject': subject,
      'message': message,
      'status': status.name,
      'order_id': orderId,
      'admin_response': adminResponse,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userEmail: json['user_email'] as String,
      type: ComplaintType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ComplaintType.other,
      ),
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ComplaintStatus.pending,
      ),
      orderId: json['order_id'] as String?,
      adminResponse: json['admin_response'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }
}
