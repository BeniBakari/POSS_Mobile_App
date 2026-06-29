class Product {
  String id;
  String name;
  String description;
  String unit;
  String unitValue;
  String quantity;
  String barcode;
  String price;
  String shopId;
  String addedBy;
  String isActive;
  //String managerId;

  Product(
      {required this.id,
      required this.name,
      required this.description,
      required this.unit,
      required this.unitValue,
      required this.quantity,
      required this.barcode,
      required this.price,
      required this.shopId,
      required this.addedBy,
      required this.isActive
      //required this.managerId
      });

  Product.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        name = item['name'],
        description = item['description'],
        unit = item['unit'],
        unitValue = item['unit_value'],
        quantity = item['quantity'],
        barcode = item['barcode'],
        price = item['price'],
        shopId = item['shop_id'],
        addedBy = item['addedBy'],
        isActive = item['is_active'];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit': unit,
      'unit_value': unitValue,
      'quantity': quantity,
      'barcode': barcode,
      'price': price,
      'shop_id': shopId,
      'added_by': addedBy,
      'is_active': isActive
    };
  }
}
