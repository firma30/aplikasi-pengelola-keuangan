class Transaction {
  final int? id;
  final String userId;
  final int categoryId;
  final String categoryName;  // Properti ini akan menyimpan nama kategori
  final double amount;
  final String transactionType;
  final DateTime transactionDate;
  final String description;

  Transaction({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName, // Tambahkan di sini juga
    required this.amount,
    required this.transactionType,
    required this.transactionDate,
    required this.description,
  });

  // Mengubah objek Transaction menjadi Map agar bisa disimpan ke dalam database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName, // Simpan nama kategori
      'amount': amount,
      'transactionType': transactionType,
      'transactionDate': transactionDate.toIso8601String(),
      'description': description,
    };
  }

  // Mengubah Map dari database menjadi objek Transaction
  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['userId'],
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      amount: map['amount'],
      transactionType: map['transactionType'],
      transactionDate: DateTime.parse(map['transactionDate']),
      description: map['description'],
    );
  }
}
