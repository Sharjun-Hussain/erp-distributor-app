import '../utils/json.dart';

class DistributorInfo {
  final String id;
  final String name;
  final String company;
  final String phone;
  final String address;
  final double creditLimit;
  final double balance;

  const DistributorInfo({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.address,
    this.creditLimit = 0,
    this.balance = 0,
  });

  factory DistributorInfo.fromJson(Map<String, dynamic> json) {
    return DistributorInfo(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      company: (json['company_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      creditLimit: toDouble(json['credit_limit']),
      balance: toDouble(json['opening_balance']),
    );
  }
}

class DistributorUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String organizationId;
  final DistributorInfo distributor;
  final bool mustChangePassword;

  const DistributorUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.organizationId,
    required this.distributor,
    this.mustChangePassword = false,
  });

  bool get isDistributor => role == 'Distributor';

  factory DistributorUser.fromJson(Map<String, dynamic> json) {
    final distributorJson =
        (json['distributor'] as Map?)?.cast<String, dynamic>();
    return DistributorUser(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: 'Distributor',
      organizationId: (json['organization_id'] ?? '').toString(),
      mustChangePassword: json['must_change_password'] == true,
      distributor: distributorJson != null
          ? DistributorInfo.fromJson(distributorJson)
          : const DistributorInfo(
              id: '',
              name: '',
              company: '',
              phone: '',
              address: '',
            ),
    );
  }
}
