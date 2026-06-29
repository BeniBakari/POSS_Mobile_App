class Shop {
  String id;
  String name;
  String address;
  String ownerId;
  //String managerId;

  Shop(
      {required this.id,
      required this.name,
      required this.address,
      required this.ownerId,
      //required this.managerId
      });

  Shop.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        name = item['name'],
        address = item['address'],
        ownerId = item['owner_id'];
  //managerId = item['manager_id'];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'owner_id': ownerId,
      //'manager_id': managerId
    };
  }
}
