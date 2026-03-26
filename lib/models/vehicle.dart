class Vehicle {
  final String? id;
  final String userId;
  final String plaka;
  final String marka;
  final String model;
  final int? yil;
  final String? renk;
  final int? kilometre;
  final DateTime? alisTarihi;
  final DateTime? satisTarihi;
  final double alisFiyati;
  final double? satisFiyati;
  final double? kar;
  final String durum; // 'stokta', 'satildi', 'rezerve'
  final String? notlar;
  final DateTime? createdAt;

  Vehicle({
    this.id,
    required this.userId,
    required this.plaka,
    required this.marka,
    required this.model,
    this.yil,
    this.renk,
    this.kilometre,
    this.alisTarihi,
    this.satisTarihi,
    required this.alisFiyati,
    this.satisFiyati,
    this.kar,
    this.durum = 'stokta',
    this.notlar,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      userId: json['user_id'],
      plaka: json['plaka'],
      marka: json['marka'],
      model: json['model'],
      yil: json['yil'],
      renk: json['renk'],
      kilometre: json['kilometre'],
      alisTarihi: json['alis_tarihi'] != null
          ? DateTime.parse(json['alis_tarihi'])
          : null,
      satisTarihi: json['satis_tarihi'] != null
          ? DateTime.parse(json['satis_tarihi'])
          : null,
      alisFiyati: (json['alis_fiyati'] as num).toDouble(),
      satisFiyati: json['satis_fiyati'] != null
          ? (json['satis_fiyati'] as num).toDouble()
          : null,
      kar: json['kar'] != null ? (json['kar'] as num).toDouble() : null,
      durum: json['durum'] ?? 'stokta',
      notlar: json['notlar'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'plaka': plaka,
      'marka': marka,
      'model': model,
      'yil': yil,
      'renk': renk,
      'kilometre': kilometre,
      'alis_tarihi': alisTarihi?.toIso8601String().split('T').first,
      'satis_tarihi': satisTarihi?.toIso8601String().split('T').first,
      'alis_fiyati': alisFiyati,
      'satis_fiyati': satisFiyati,
      'durum': durum,
      'notlar': notlar,
    };
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? plaka,
    String? marka,
    String? model,
    int? yil,
    String? renk,
    int? kilometre,
    DateTime? alisTarihi,
    DateTime? satisTarihi,
    double? alisFiyati,
    double? satisFiyati,
    double? kar,
    String? durum,
    String? notlar,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plaka: plaka ?? this.plaka,
      marka: marka ?? this.marka,
      model: model ?? this.model,
      yil: yil ?? this.yil,
      renk: renk ?? this.renk,
      kilometre: kilometre ?? this.kilometre,
      alisTarihi: alisTarihi ?? this.alisTarihi,
      satisTarihi: satisTarihi ?? this.satisTarihi,
      alisFiyati: alisFiyati ?? this.alisFiyati,
      satisFiyati: satisFiyati ?? this.satisFiyati,
      kar: kar ?? this.kar,
      durum: durum ?? this.durum,
      notlar: notlar ?? this.notlar,
    );
  }
}
