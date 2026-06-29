class Register {
  String id;
  String openingCash;
  String closingCash;
  String openedBy;
  String closedBy;
  String shopId;
  String createdAt;
  String updatedAt;

  Register(
      {required this.id,
      required this.openingCash,
      required this.shopId,
      required this.closingCash,
      required this.closedBy,
      required this.openedBy,
      required this.updatedAt,
      required this.createdAt});

  Register.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        openingCash = item['opening_cash'],
        closingCash = item['closing_cash'],
        openedBy = item['opened_by'],
        closedBy = item['closed_by'],
        shopId = item['shop_id'],
        createdAt = item['created_at'],
        updatedAt = item['updated_at'];

  Map<String, Object> toMap() {
    return {
      'id': id,
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'opened_by': openedBy,
      'closed_by': closedBy,
      'shop_id': shopId,
      'created_at': createdAt,
      'updated_at': updatedAt
    };
  }
}
