import 'package:intl/intl.dart';

class ModellBarang {
  final String nama;
  final int harga;
  final int stok;
  final String lokasi;
  final DateTime waktu;
  final String jenis;

  ModellBarang({
    required this.nama,
    required this.harga,
    required this.stok,
    required this.lokasi,
    required this.waktu,
    required this.jenis,
  });

  factory ModellBarang.fromJson(Map<String, dynamic> json) {
    return ModellBarang(
      nama: json['nama'],
      harga: json['harga'],
      stok: json['stok'],
      lokasi: json['lokasi'],
      waktu: DateTime.parse(json['waktu']),
      jenis: json['jenis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'lokasi': lokasi,
      'waktu': DateFormat('yyyy-MM-dd').format(waktu),
      'jenis': jenis,
    };
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
