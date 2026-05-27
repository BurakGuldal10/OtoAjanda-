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

  // Araç alındığı kişi (satıcı — galeri'ye satan kişi)
  final String? saticiAdi;
  final String? saticiTelefon;
  final String? saticiAdres;

  // Araç satıldığı kişi (alıcı — galeriden alan kişi)
  final String? aliciAdi;
  final String? aliciTelefon;
  final String? aliciAdres;

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
    this.saticiAdi,
    this.saticiTelefon,
    this.saticiAdres,
    this.aliciAdi,
    this.aliciTelefon,
    this.aliciAdres,
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
      saticiAdi: json['satici_adi'],
      saticiTelefon: json['satici_telefon'],
      saticiAdres: json['satici_adres'],
      aliciAdi: json['alici_adi'],
      aliciTelefon: json['alici_telefon'],
      aliciAdres: json['alici_adres'],
    );
  }

  /// Veritabanı payload'ı üretir.
  ///
  /// - `forUpdate: false` (varsayılan) — insert için; `user_id` dahil
  /// - `forUpdate: true` — update için; `user_id` ve `id` payload'a eklenmez
  ///   (id WHERE klozunda kullanılır, user_id ise RLS tarafından korunur ve
  ///    update sırasında değiştirilmemelidir).
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    return {
      if (!forUpdate && id != null) 'id': id,
      if (!forUpdate) 'user_id': userId,
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
      'satici_adi': saticiAdi,
      'satici_telefon': saticiTelefon,
      'satici_adres': saticiAdres,
      'alici_adi': aliciAdi,
      'alici_telefon': aliciTelefon,
      'alici_adres': aliciAdres,
    };
  }
}
