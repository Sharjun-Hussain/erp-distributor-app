class Shop {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final double creditLimit;
  final double balance;
  final bool isActive;

  const Shop({
    required this.id,
    required this.name,
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.creditLimit = 0,
    this.balance = 0,
    this.isActive = true,
  });

  Shop copyWith({
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    bool? isActive,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      balance: balance,
      isActive: isActive ?? this.isActive,
    );
  }
}
