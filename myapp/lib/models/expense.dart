class ExpenseMember {
  final String userId;
  final String name;
  final String? avatarUrl;
  final double amount;
  final bool isPaid;

  ExpenseMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.amount,
    this.isPaid = false,
  });

  factory ExpenseMember.fromJson(Map<String, dynamic> json) {
    final profile =
        (json['profiles_public'] ?? json['profiles']) as Map<String, dynamic>?;
    final isPaidVal = json['is_paid'] == true || json['status'] == 'paid';
    final amountVal = ((json['amount'] ?? json['share_amount'] ?? 0) as num)
        .toDouble();

    return ExpenseMember(
      userId: (json['user_id'] ?? '') as String,
      name:
          (profile?['full_name'] ?? profile?['username'] ?? 'Squad Member')
              as String,
      avatarUrl: profile?['avatar_url'] as String?,
      amount: amountVal,
      isPaid: isPaidVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'status': isPaid ? 'paid' : 'pending',
    };
  }

  ExpenseMember copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    double? amount,
    bool? isPaid,
  }) {
    return ExpenseMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class Expense {
  final String id;
  final String activityId;
  final String creatorId;
  final String creatorName;
  final String description;
  final double totalAmount;
  final String? upiId;
  final List<ExpenseMember> members;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.activityId,
    required this.creatorId,
    required this.creatorName,
    required this.description,
    required this.totalAmount,
    this.upiId,
    required this.members,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final creator =
        (json['profiles_public'] ?? json['profiles']) as Map<String, dynamic>?;
    final sharesRaw = (json['expense_shares'] as List<dynamic>?) ?? [];
    final membersList = sharesRaw
        .map((s) => ExpenseMember.fromJson(s as Map<String, dynamic>))
        .toList();

    return Expense(
      id: (json['id'] ?? '') as String,
      activityId: (json['activity_id'] ?? '') as String,
      creatorId: (json['created_by'] ?? json['creator_id'] ?? '') as String,
      creatorName:
          (creator?['full_name'] ?? creator?['username'] ?? 'Host') as String,
      description: (json['description'] ?? '') as String,
      totalAmount: ((json['total_amount'] ?? 0) as num).toDouble(),
      upiId: json['upi_id'] as String?,
      members: membersList,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'created_by': creatorId,
      'description': description,
      'total_amount': totalAmount,
      'upi_id': upiId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get perHead => members.isEmpty ? 0 : totalAmount / members.length;

  int get paidCount => members.where((m) => m.isPaid).length;

  Expense copyWith({
    String? id,
    String? activityId,
    String? creatorId,
    String? creatorName,
    String? description,
    double? totalAmount,
    String? upiId,
    List<ExpenseMember>? members,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      upiId: upiId ?? this.upiId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
