class Purchase {
  String id;
  String shopId;
  String quantity;
  String description;
  String productId;
  String cost;
  String addedBy;

  Purchase({
    required this.id,
    required this.shopId,
    required this.quantity,
    required this.description,
    required this.productId,
    required this.cost,
    required this.addedBy,
  });

  Purchase.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        productId = item['product_id'],
        cost = item['product_id'],
        quantity = item['quantity'],
        description = item['description'],
        shopId = item['shop_id'],
        addedBy = item['added_by'];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'description': description,
      'cost': cost,
      'quantity': quantity,
      'shop_id': shopId,
      'added_by': addedBy,
    };
  }
}
