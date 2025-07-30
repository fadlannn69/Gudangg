import 'package:intl/intl.dart';

class ModelBarang {
  final int id;
  final String nama;
  final int harga;
  int stok;
  int terjual;
  final String lokasi;
  final DateTime waktu;
  final DateTime? waktujual;
  final String jenis;
  final String gambar;

  ModelBarang({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.lokasi,
    required this.waktu,
    this.waktujual,
    required this.jenis,
    required this.gambar,
    required this.terjual,
  });

  factory ModelBarang.fromJson(Map<String, dynamic> json) {
    return ModelBarang(
      id: json['id'],
      nama: json['nama'],
      harga: json['harga'],
      stok: json['stok'],
      lokasi: json['lokasi'],
      waktu: DateTime.parse(json['waktu']),
      waktujual:
          json['waktujual'] != null ? DateTime.parse(json['waktujual']) : null,
      jenis: json['jenis'],
      gambar: json['gambar'] ?? '',
      terjual: json['terjual'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'lokasi': lokasi,
      'waktu': DateFormat('yyyy-MM-dd').format(waktu),
      'waktujual':
          waktujual != null
              ? DateFormat('yyyy-MM-dd').format(waktujual!)
              : null,
      'jenis': jenis,
      'gambar': gambar,
      'terjual': terjual,
    };
  }

  ModelBarang copyWith({
    int? id,
    String? nama,
    int? harga,
    int? stok,
    String? lokasi,
    DateTime? waktu,
    DateTime? waktujual,
    String? jenis,
    String? gambar,
    int? terjual,
  }) {
    return ModelBarang(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      lokasi: lokasi ?? this.lokasi,
      waktu: waktu ?? this.waktu,
      waktujual: waktujual ?? this.waktujual,
      jenis: jenis ?? this.jenis,
      gambar: gambar ?? this.gambar,
      terjual: terjual ?? this.terjual,
    );
  }

  @override
  String toString() {
    return 'ModelBarang(id: $id, nama: $nama, harga: $harga, stok: $stok, lokasi: $lokasi, waktu: $waktu, waktujual: $waktujual, jenis: $jenis, gambar: $gambar, terjual: $terjual)';
  }
}

class HapussBarang {
  final String nama;

  HapussBarang({required this.nama});

  factory HapussBarang.fromJson(Map<String, dynamic> json) {
    return HapussBarang(nama: json['nama']);
  }

  Map<String, dynamic> toJson() {
    return {"nama": nama};
  }
}

class BarangUpdate {
  final int? harga;
  final int? stok;
  final DateTime? waktu;

  BarangUpdate({this.harga, this.stok, this.waktu});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (harga != null) map['harga'] = harga;
    if (stok != null) map['stok'] = stok;
    if (waktu != null) {
      map['waktu'] = DateFormat('yyyy-MM-dd').format(waktu!);
    }
    return map;
  }
}

class ModelHistori {
  final int id;
  final String nama;
  final int harga;
  final int terjual;
  final int totalHarga;
  final DateTime waktujual;

  ModelHistori({
    required this.id,
    required this.nama,
    required this.harga,
    required this.terjual,
    required this.totalHarga,
    required this.waktujual,
  });

  factory ModelHistori.fromJson(Map<String, dynamic> json) {
    return ModelHistori(
      id: json['id'],
      nama: json['nama'],
      harga: json['harga'] ?? 0,
      terjual: json['terjual'] ?? 0,
      totalHarga:
          json['total_harga'] ?? (json['harga'] ?? 0) * (json['terjual'] ?? 0),
      waktujual: DateTime.parse(json['waktujual']),
    );
  }
}
