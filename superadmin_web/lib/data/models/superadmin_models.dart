class Gym {
  final String id;
  final String name;
  final String ownerName;
  final String email;
  final String status; // 'Active', 'Pending', 'Suspended'
  final DateTime registeredAt;
  final String subscriptionPlan;
  final int activeMembers;

  Gym({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.status,
    required this.registeredAt,
    required this.subscriptionPlan,
    required this.activeMembers,
  });
}

class PlatformStats {
  final int totalGyms;
  final int activeGyms;
  final int pendingGyms;
  final int totalGymOwners;
  final int activeMembers;
  final int trainers;
  final double monthlyRevenue;
  final double annualRevenue;

  PlatformStats({
    required this.totalGyms,
    required this.activeGyms,
    required this.pendingGyms,
    required this.totalGymOwners,
    required this.activeMembers,
    required this.trainers,
    required this.monthlyRevenue,
    required this.annualRevenue,
  });
}

class Invoice {
  final String id;
  final String gymName;
  final String ownerName;
  final double amount;
  final String status; // 'Paid', 'Pending', 'Overdue'
  final DateTime issueDate;
  final DateTime dueDate;

  Invoice({
    required this.id,
    required this.gymName,
    required this.ownerName,
    required this.amount,
    required this.status,
    required this.issueDate,
    required this.dueDate,
  });
}

class Transaction {
  final String id;
  final String gymName;
  final double amount;
  final DateTime date;
  final String paymentMethod; // e.g., 'Credit Card', 'Bank Transfer'
  final String type; // e.g., 'Subscription', 'Setup Fee', 'Refund'
  final String status; // 'Success', 'Pending', 'Failed'

  Transaction({
    required this.id,
    required this.gymName,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.type,
    required this.status,
  });
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String? createdBy;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.createdBy,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      createdBy: json['createdBy'],
    );
  }
}
