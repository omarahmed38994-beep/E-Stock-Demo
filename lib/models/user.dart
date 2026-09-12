class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? branchId;
  final int companyId;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.companyId,
    this.branchId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        role: json['role'],
        companyId: json['company_id'],
        branchId: json['branch_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'company_id': companyId,
        'branch_id': branchId,
      };

  /// Role-based access helpers used to hide UI the current role shouldn't see.
  bool get canSeeAllBranches => role != 'Branch Manager';
  bool get isOwnerOrGM => role == 'Owner' || role == 'General Manager';
  bool get canApproveTransfers => role == 'Owner' || role == 'General Manager' || role == 'Inventory Manager';
  bool get canSeeFinancials => role == 'Owner' || role == 'General Manager' || role == 'Accountant';
  bool get canSeeActivityAudit => role == 'Owner' || role == 'General Manager' || role == 'Auditor';
}
