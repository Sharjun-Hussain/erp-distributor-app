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
}

class DistributorUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String organizationId;
  final DistributorInfo distributor;

  const DistributorUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.organizationId,
    required this.distributor,
  });

  bool get isDistributor => role == 'Distributor';
}
