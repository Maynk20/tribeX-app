class ExpenseMember {
  final String? shareId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final double amount;
  final bool isPaid;

  ExpenseMember({
    this.shareId,
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
      shareId: json['id'] as String?,
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
      if (shareId != null) 'id': shareId,
      'user_id': userId,
      'amount': amount,
      'status': isPaid ? 'paid' : 'pending',
    };
  }

  ExpenseMember copyWith({
    String? shareId,
    String? userId,
    String? name,
    String? avatarUrl,
    double? amount,
    bool? isPaid,
  }) {
    return ExpenseMember(
      shareId: shareId ?? this.shareId,
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

  /// Distributes [totalAmount] equally among [participants] down to the exact paisa (cents),
  /// distributing any remainder paise among the first members so the sum of all shares matches [totalAmount] exactly.
  static List<ExpenseMember> calculateEqualSplit({
    required List<ExpenseMember> participants,
    required double totalAmount,
    String? payerId,
  }) {
    if (participants.isEmpty) return const [];
    if (totalAmount <= 0) {
      return participants
          .map(
            (m) => m.copyWith(
              amount: 0.0,
              isPaid: payerId != null && m.userId == payerId,
            ),
          )
          .toList();
    }

    final totalPaise = (totalAmount * 100).round();
    final count = participants.length;
    final basePaise = totalPaise ~/ count;
    final remainderPaise = totalPaise % count;

    final result = <ExpenseMember>[];
    for (int i = 0; i < count; i++) {
      final sharePaise = i < remainderPaise ? basePaise + 1 : basePaise;
      final shareAmount = sharePaise / 100.0;
      final m = participants[i];
      final isPaid = payerId != null ? (m.userId == payerId) : m.isPaid;
      result.add(m.copyWith(amount: shareAmount, isPaid: isPaid));
    }
    return result;
  }
}
