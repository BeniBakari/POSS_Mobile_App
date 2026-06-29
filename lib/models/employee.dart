class Employee {
  String id;
  String userId;
  String shopId;
  String addedBy;

  Employee({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.addedBy,
  });

  Employee.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        userId = item['user_id'],
        shopId = item['shop_id'],
        addedBy = item['added_by'];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'shop_id': shopId,
      'added_by': addedBy,
    };
  }
}
