import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_web/features/members/providers/members_provider.dart';

class BroadcastModel {
  final String id;
  final String subject;
  final String message;
  final DateTime createdAt;

  BroadcastModel({
    required this.id,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    return BroadcastModel(
      id: json['_id'],
      subject: json['subject'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}

class BroadcastReceipt {
  final Map<String, dynamic> member;
  final bool isRead;
  final DateTime? readAt;

  BroadcastReceipt({
    required this.member,
    required this.isRead,
    this.readAt,
  });

  factory BroadcastReceipt.fromJson(Map<String, dynamic> json) {
    return BroadcastReceipt(
      member: json['member'] ?? {},
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']).toLocal() : null,
    );
  }
}

class BroadcastDetails {
  final BroadcastModel broadcast;
  final List<BroadcastReceipt> receipts;

  BroadcastDetails({
    required this.broadcast,
    required this.receipts,
  });

  factory BroadcastDetails.fromJson(Map<String, dynamic> json) {
    return BroadcastDetails(
      broadcast: BroadcastModel.fromJson(json['broadcast']),
      receipts: (json['receipts'] as List).map((r) => BroadcastReceipt.fromJson(r)).toList(),
    );
  }
}

final broadcastsProvider = FutureProvider.autoDispose<List<BroadcastModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get('/notifications/broadcast');
  return (res as List).map((b) => BroadcastModel.fromJson(b)).toList();
});

final broadcastDetailsProvider = FutureProvider.family.autoDispose<BroadcastDetails, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.get('/notifications/broadcast/$id');
  return BroadcastDetails.fromJson(res);
});
