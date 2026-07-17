class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String membershipPlan;
  final String status; // 'Active', 'Expired', 'Expiring Soon'
  final DateTime joinDate;
  final DateTime expiryDate;
  final int totalCheckIns;
  final String? imageUrl;
  final String address;
  final String? documentUrl;
  final String? trainerId;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.membershipPlan,
    required this.status,
    required this.joinDate,
    required this.expiryDate,
    required this.totalCheckIns,
    this.imageUrl,
    this.address = '',
    this.documentUrl,
    this.trainerId,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      membershipPlan: json['membershipPlan'] ?? '',
      status: json['status'] ?? 'Active',
      joinDate: json['joinDate'] != null ? DateTime.parse(json['joinDate']) : DateTime.now(),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : DateTime.now(),
      totalCheckIns: json['totalCheckIns'] ?? 0,
      imageUrl: json['imageUrl'],
      address: json['address'] ?? '',
      documentUrl: json['documentUrl'],
      trainerId: json['trainerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'membershipPlan': membershipPlan,
      'status': status,
      'joinDate': joinDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'totalCheckIns': totalCheckIns,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'address': address,
      if (documentUrl != null) 'documentUrl': documentUrl,
      if (trainerId != null) 'trainerId': trainerId,
    };
  }
}

class Trainer {
  final String id;
  final String name;
  final String specialization;
  final int assignedMembers;
  final double rating;
  final String? imageUrl;
  final String email;
  final String phone;
  final int experienceYears;
  final String about;
  final List<String> certificates;

  Trainer({
    required this.id,
    required this.name,
    required this.specialization,
    required this.assignedMembers,
    required this.rating,
    this.imageUrl,
    this.email = '',
    this.phone = '',
    this.experienceYears = 0,
    this.about = '',
    this.certificates = const [],
  });

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      assignedMembers: json['assignedMembers'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      experienceYears: json['experienceYears'] ?? 0,
      about: json['about'] ?? '',
      certificates: List<String>.from(json['certificates'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'specialization': specialization,
      'assignedMembers': assignedMembers,
      'rating': rating,
      'email': email,
      'phone': phone,
      'experienceYears': experienceYears,
      'about': about,
      'certificates': certificates,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class GymOwnerStats {
  final double monthlyRevenue;
  final double monthlyExpenses;
  final int activeMembers;
  final int todayCheckIns;
  final int membershipRenewals;
  final int totalTrainers;
  final int totalStaff;

  GymOwnerStats({
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.activeMembers,
    required this.todayCheckIns,
    required this.membershipRenewals,
    required this.totalTrainers,
    required this.totalStaff,
  });
}

class Staff {
  final String id;
  final String name;
  final String role;
  final String shift;
  final String phone;
  final String email;
  final String? imageUrl;
  final String? idProofUrl;

  Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.shift,
    this.phone = '',
    this.email = '',
    this.imageUrl,
    this.idProofUrl,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      shift: json['shift'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'],
      idProofUrl: json['idProofUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'role': role,
      'shift': shift,
      'phone': phone,
      'email': email,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (idProofUrl != null) 'idProofUrl': idProofUrl,
    };
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String time;

  NotificationModel({required this.id, required this.title, required this.time});
}

class MessageModel {
  final String id;
  final String sender;
  final String content;
  final String time;
  final bool isSentByMe;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.time,
    this.isSentByMe = false,
    this.isRead = true,
  });

  MessageModel copyWith({
    String? id,
    String? sender,
    String? content,
    String? time,
    bool? isSentByMe,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      time: time ?? this.time,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      isRead: isRead ?? this.isRead,
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String date;

  EventModel({required this.id, required this.title, required this.date});

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'title': title,
      'date': date,
    };
  }
}

class MembershipPlan {
  final String id;
  final String name;
  final double price;
  final double? discountPrice;
  final String duration;
  final List<String> features;
  final String colorHex;
  final String currencySymbol;
  final bool isActive;

  MembershipPlan({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice,
    required this.duration,
    required this.features,
    this.colorHex = '#CFFF50',
    this.currencySymbol = '₹',
    this.isActive = true,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: json['discountPrice'] != null ? (json['discountPrice'] as num).toDouble() : null,
      duration: json['duration'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      colorHex: json['colorHex'] ?? '#CFFF50',
      currencySymbol: json['currencySymbol'] ?? '₹',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'price': price,
      if (discountPrice != null) 'discountPrice': discountPrice,
      'duration': duration,
      'features': features,
      'colorHex': colorHex,
      'currencySymbol': currencySymbol,
      'isActive': isActive,
    };
  }
}

class AttendanceRecord {
  final String id;
  final String memberId;
  final DateTime date;
  final DateTime? checkInTime;
  final String status; // 'Present', 'Absent'

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.date,
    this.checkInTime,
    required this.status,
  });
}

class PaymentRecord {
  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final String paymentMethod; // 'Cash', 'Card', 'UPI'
  final String status; // 'Completed', 'Pending', 'Failed'

  PaymentRecord({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.status,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['_id'] ?? '',
      memberId: json['memberId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      status: json['status'] ?? 'Completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'memberId': memberId,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'status': status,
    };
  }
}

class ExpenseRecord {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category; // 'Rent', 'Equipment', 'Salary', 'Utilities', 'Marketing'
  final String status; // 'Paid', 'Pending'

  ExpenseRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.status,
  });

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    return ExpenseRecord(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      category: json['category'] ?? 'Rent',
      status: json['status'] ?? 'Paid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'status': status,
    };
  }
}

class InventoryItem {
  final String id;
  final String itemName;
  final String category;
  final int quantity;
  final String unit;
  final double purchasePrice;
  final double? sellingPrice;
  final String? supplier;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final int? minimumStock;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    this.sellingPrice,
    this.supplier,
    this.purchaseDate,
    this.expiryDate,
    this.minimumStock,
  });

  String get status {
    if (expiryDate != null && expiryDate!.isBefore(DateTime.now())) return 'Expired';
    if (quantity <= 0) return 'Out of Stock';
    if (minimumStock != null && quantity <= minimumStock!) return 'Low Stock';
    return 'In Stock';
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'Piece',
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: json['sellingPrice'] != null ? json['sellingPrice'].toDouble() : null,
      supplier: json['supplier'],
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      minimumStock: json['minimumStock'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'supplier': supplier,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'minimumStock': minimumStock,
    };
  }
}

class Equipment {
  final String id;
  final String machineName;
  final String equipmentType;
  final String brand;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String status;
  final String location;
  final DateTime? warrantyExpiry;
  final String? supplier;
  final String? serialNumber;
  final String? notes;

  Equipment({
    required this.id,
    required this.machineName,
    required this.equipmentType,
    required this.brand,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.status,
    required this.location,
    this.warrantyExpiry,
    this.supplier,
    this.serialNumber,
    this.notes,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['_id'] ?? '',
      machineName: json['machineName'] ?? '',
      equipmentType: json['equipmentType'] ?? '',
      brand: json['brand'] ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate'] ?? DateTime.now().toIso8601String()),
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'Active',
      location: json['location'] ?? '',
      warrantyExpiry: json['warrantyExpiry'] != null ? DateTime.parse(json['warrantyExpiry']) : null,
      supplier: json['supplier'],
      serialNumber: json['serialNumber'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machineName': machineName,
      'equipmentType': equipmentType,
      'brand': brand,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'status': status,
      'location': location,
      'warrantyExpiry': warrantyExpiry?.toIso8601String(),
      'supplier': supplier,
      'serialNumber': serialNumber,
      'notes': notes,
    };
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'Payment', 'Inventory', 'Maintenance', 'System'
  final bool isRead;
  final String? targetRoute;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.targetRoute,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    String? targetRoute,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      targetRoute: targetRoute ?? this.targetRoute,
    );
  }
}
