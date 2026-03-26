class Expense {
  final String? id;
  final String vehicleId;
  final String userId;
  final String tur; // 'bakim', 'boya', 'sigorta', 'vergi', 'diger'
  final double tutar;
  final String? aciklama;
  final DateTime? tarih;
  final DateTime? createdAt;

  Expense({
    this.id,
    required this.vehicleId,
    required this.userId,
    required this.tur,
    required this.tutar,
    this.aciklama,
    this.tarih,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      userId: json['user_id'],
      tur: json['tur'],
      tutar: (json['tutar'] as num).toDouble(),
      aciklama: json['aciklama'],
      tarih: json['tarih'] != null ? DateTime.parse(json['tarih']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'user_id': userId,
      'tur': tur,
      'tutar': tutar,
      'aciklama': aciklama,
      'tarih': tarih?.toIso8601String().split('T').first,
    };
  }
}
