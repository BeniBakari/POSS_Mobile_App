class Expense {
  String id;
  String description;
  String amount;
  String addedBy;
  String shopId;
  String createdAt;
  String updatedAt;

  Expense(
      {required this.id,
      required this.description,
      required this.shopId,
      required this.amount,
      required this.addedBy,
      required this.updatedAt,
      required this.createdAt});

  Expense.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        description = item['description'],
        amount = item['amount'],
        addedBy = item['added_by'],
        shopId = item['shop_id'],
        createdAt = item['created_at'],
        updatedAt = item['updated_at'];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'added_by': addedBy,
      'shop_id': shopId,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }
}
