import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/auth_service.dart';
import 'package:gudkoptell/home/dashboard.dart';
import 'package:gudkoptell/model/model_barang.dart';
import 'package:gudkoptell/registry/login.dart';
import 'package:intl/intl.dart';

class Jual extends StatefulWidget {
  @override
  State<Jual> createState() => _JualState();
}

class _JualState extends State<Jual> {
  List<ModelBarang> daftarBarang = [];
  List<ModelBarang> keranjangBarang = [];
  Map<ModelBarang, int> jumlahBarang = {};
  bool isLoading = true;
  late BuildContext scaffoldContext;

  @override
  void initState() {
    super.initState();
    fetchBarang();
  }

  Future<void> _checkoutBarang() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null) return;

    final dio = Dio();
    final token = await AuthService.getToken();
    dio.options.headers['Authorization'] = 'Bearer $token';

    final List<Map<String, dynamic>> checkoutData = [];

    try {
      for (var barang in keranjangBarang) {
        int jumlah = jumlahBarang[barang] ?? 1;
        String waktuPembelian = DateFormat('yyyy-MM-dd').format(DateTime.now());

        for (int i = 0; i < jumlah; i++) {
          final response = await dio.put('$baseUrl/barang/${barang.id}/jual');

          if (response.statusCode != 200) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Gagal menjual ${barang.nama}"),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        await dio.post(
          '$baseUrl/barang/addhistori',
          data: {
            'nama': barang.nama,
            'terjual': jumlah,
            'harga': barang.harga,
            'waktujual': DateTime.now().toIso8601String(),
          },
        );

        checkoutData.add({
          'nama': barang.nama,
          'jumlah': jumlah,
          'waktu': waktuPembelian,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Checkout berhasil"),
          backgroundColor: Colors.green,
        ),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Detail Barang Terjual!", textAlign: TextAlign.center),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: checkoutData.length,
                itemBuilder: (context, index) {
                  final item = checkoutData[index];
                  return ListTile(
                    leading: Icon(Icons.shopping_cart),
                    title: Text(item['nama']),
                    subtitle: Text("Jumlah: ${item['jumlah']}"),
                    trailing: Text(item['waktu']),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Tutup", textAlign: TextAlign.center),
              ),
            ],
          );
        },
      );

      setState(() {
        keranjangBarang.clear();
        jumlahBarang.clear();
      });

      fetchBarang();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan saat checkout"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void tambahKeKeranjang(ModelBarang barang) {
    setState(() {
      final bool baruDitambahkan = !keranjangBarang.contains(barang);

      if (baruDitambahkan) {
        keranjangBarang.add(barang);
        jumlahBarang[barang] = jumlahBarang[barang] ?? 1;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${barang.nama} sudah ada di keranjang")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${barang.nama} ditambahkan  ke keranjang")),
        );
      }
    });
  }

  Future<void> fetchBarang() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("API_BASE_URL tidak ditemukan di .env")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final token = await AuthService.getToken();
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get(
        "$baseUrl/barang/ambil",
        queryParameters: {'skip': 0, 'limit': 1000},
      );

      if (response.statusCode == 200) {
        if (response.data is! List) throw Exception("Data barang tidak valid");

        final List data = response.data;
        final allBarang = data.map((e) => ModelBarang.fromJson(e)).toList();

        setState(() {
          daftarBarang = allBarang;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await AuthService.clearToken();
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => Login()));
        }
      } else {
        throw Exception("Gagal memuat data barang");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data barang")));
      setState(() => isLoading = false);
    }
  }

  Map<String, List<ModelBarang>> _kelompokkanBarang(List<ModelBarang> daftar) {
    final Map<String, List<ModelBarang>> kelompok = {};

    for (var barang in daftar) {
      final kategori = barang.nama.split(' ').first;

      if (!kelompok.containsKey(kategori)) {
        kelompok[kategori] = [];
      }

      kelompok[kategori]!.add(barang);
    }

    return kelompok;
  }

  Widget _buildItemBarang(ModelBarang barang) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.r, left: 1.r, right: 1.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl:
                  '${dotenv.env['API_BASE_URL']}/uploaded_images/${barang.gambar}',
              width: 50.w,
              height: 50.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.broken_image),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barang.nama,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Stok: ${barang.stok}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if ((jumlahBarang[barang] ?? 1) > 1) {
                            jumlahBarang[barang] =
                                (jumlahBarang[barang] ?? 1) - 1;
                          } else {
                            jumlahBarang.remove(barang);
                            keranjangBarang.remove(barang);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "${barang.nama} Dihapus Dari Keranjang",
                                ),
                              ),
                            );
                          }
                        });
                      },
                    ),

                    Text('${jumlahBarang[barang] ?? 1}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          if (!keranjangBarang.contains(barang)) {
                            keranjangBarang.add(barang);
                          }
                          jumlahBarang[barang] =
                              (jumlahBarang[barang] ?? 0) + 1;
                        });
                      },
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    minimumSize: Size(75, 25),
                  ),
                  onPressed: () {
                    setState(() {
                      if (!keranjangBarang.contains(barang)) {
                        keranjangBarang.add(barang);
                        jumlahBarang[barang] = jumlahBarang[barang] ?? 1;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${barang.nama} Sudah Ada Di Keranjang",
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              " ${jumlahBarang[barang]} ${barang.nama}  Ditambahkan Ke Keranjang",
                            ),
                          ),
                        );
                      }
                    });
                  },

                  child: Icon(Icons.sell_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Padding(
          padding: EdgeInsets.only(left: 70.w),
          child: Text(
            "Jual Barang",
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sell_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    height: 600,
                    child:
                        keranjangBarang.isEmpty
                            ? Center(child: Text("Keranjang kosong"))
                            : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: keranjangBarang.length,
                                    itemBuilder: (context, index) {
                                      final item = keranjangBarang[index];
                                      return ListTile(
                                        leading: CachedNetworkImage(
                                          imageUrl:
                                              '${dotenv.env['API_BASE_URL']}/uploaded_images/${item.gambar}',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) =>
                                                  CircularProgressIndicator(),
                                          errorWidget:
                                              (context, url, error) =>
                                                  Icon(Icons.broken_image),
                                        ),
                                        title: Text(
                                          item.nama,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Jumlah Pesanan: ${jumlahBarang[item] ?? 1}',
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              keranjangBarang.removeAt(index);
                                              jumlahBarang.remove(item);
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: Size(double.infinity, 48),
                                  ),
                                  onPressed: () {
                                    _checkoutBarang();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Penjualan berhasil"),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.sell, color: Colors.black),
                                  label: Text(
                                    "Jual Barang",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              fetchBarang();
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.all(10.r),
                children:
                    _kelompokkanBarang(daftarBarang).entries.map((entry) {
                      final namaKelompok = entry.key;
                      final barangKelompok = entry.value;

                      return ExpansionTile(
                        title: Text(
                          namaKelompok,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: barangKelompok.map(_buildItemBarang).toList(),
                      );
                    }).toList(),
              ),
    );
  }
}
