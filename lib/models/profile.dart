class Profile {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final String roleId;
  final String dob;
  final String imagePath;
  final String gender;
  final String address;
  final String token;

  Profile(
      {
      required this.id,  
      required this.firstname,
      required this.lastname,
      required this.email,
      required this.token,
      required this.roleId,
      this.phone = '',
      this.imagePath = '',
      this.dob = '',
      this.gender = '',
      this.address = ''});

  Profile.fromMap(Map<String, dynamic> item)
      : 
        id = item['id'],
        firstname = item["firstname"],
        lastname = item['lastname'],
        email = item['email'],
        roleId = item['roleId'],
        phone = item['phone'].toString() == "null" ? item['phone'] : '',
        imagePath =
            item['imagePath'].toString() == "null" ? item['imagePath'] : '',
        dob = item['dob'].toString() == "null" ? item['dob'] : '',
        gender = item['gender'].toString() == "null" ? item['gender'] : '',
        address = item['address'].toString() == "null" ? item['address'] : '',
        token = item["token"];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'roleId': roleId,
      'phone': phone,
      'imagePath': imagePath,
      'dob': dob,
      'gender': gender,
      'address': address,
      'token': token
    };
  }
}
