class User {
  int id;
  String firstName;
  String lastName;
  String email;
  String? gender;
  String? phone;
  String? imagePath;
  String? dob;
  String? address;
  List<String> roleNames;
  List<String> permissions;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.address,
    this.phone,
    this.gender,
    this.imagePath,
    this.dob,
    required this.roleNames,
    required this.permissions,
  });

  User.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        firstName = item['first_name'] ?? '',
        lastName = item['last_name'] ?? '',
        email = item['email'] ?? '',
        address = item['address'],
        phone = item['phone'],
        gender = item['gender'],
        imagePath = item['imagePath'],
        dob = item['dob'],
        roleNames = List<String>.from(item['roleNames'] ?? []),
        permissions = List<String>.from(item['permissions'] ?? []);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'address': address ?? '',
      'phone': phone ?? '',
      'gender': gender ?? '',
      'imagePath': imagePath ?? '',
      'dob': dob ?? '',
      // No list fields — UserOps handles JSON encoding
    };
  }

  bool isAdmin() => roleNames.contains('Admin');
}