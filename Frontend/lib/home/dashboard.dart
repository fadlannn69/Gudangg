import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/home/add.dart';
import 'package:gudkoptell/home/delete.dart';
import 'package:gudkoptell/home/histori.dart';
import 'package:gudkoptell/home/jual.dart';
import 'package:gudkoptell/home/update.dart';
import 'package:gudkoptell/model/model_barang.dart';
import 'package:gudkoptell/registry/login.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Dashboard extends StatefulWidget {
  static const routeName = '/dashboard';

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<ModelBarang> daftarBarang = [];
  List<ModelBarang> semuaBarang = [];
  bool isLoading = true;
  String filterJenis = 'Semua Jenis';
  int pageIndex = 0;
  final int itemsPerPage = 10;
  bool isPaginationEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchBarang();
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

      final params = {'skip': 0, 'limit': 1000};

      if (filterJenis != 'Semua Jenis') {
        params['jenis'] == filterJenis;
      }

      final response = await dio.get(
        "$baseUrl/barang/ambil",
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        if (response.data is! List) throw Exception("Data barang tidak valid");

        final List data = response.data;
        final allBarang = data.map((e) => ModelBarang.fromJson(e)).toList();

        setState(() {
          semuaBarang = allBarang;
          if (filterJenis == 'Semua Jenis') {
            daftarBarang = semuaBarang;
            isPaginationEnabled = false;
          } else {
            daftarBarang =
                semuaBarang.where((b) => b.jenis == filterJenis).toList();
            isPaginationEnabled = true;
          }
          isLoading = false;
          pageIndex = 0;
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
      ).showSnackBar(SnackBar(content: Text("Error ${e}")));
      setState(() => isLoading = false);
    }
  }

  void nextPage() {
    final maxPage = (daftarBarang.length / itemsPerPage).ceil() - 1;
    if (pageIndex < maxPage) {
      setState(() => pageIndex++);
    }
  }

  void prevPage() {
    if (pageIndex > 0) {
      setState(() => pageIndex--);
    }
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15, right: 15),
          child: Text("$label ", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15, right: 15),
          child: Text(":          ${value}"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginated =
        isPaginationEnabled
            ? daftarBarang
                .skip(pageIndex * itemsPerPage)
                .take(itemsPerPage)
                .toList()
            : daftarBarang;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Padding(
          padding: EdgeInsets.only(left: 95.w),
          child: Text(
            "Gudang!",
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
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
              : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Cari Berdasarkan Jenis :"),
                        DropdownButton<String>(
                          value: filterJenis,
                          items:
                              [
                                'Semua Jenis',
                                'Barang Habis Pakai',
                                'Barang Asset',
                              ].map((jenis) {
                                return DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                filterJenis = value;
                                if (filterJenis == 'Semua Jenis') {
                                  daftarBarang = semuaBarang;
                                  isPaginationEnabled = true;
                                } else {
                                  daftarBarang =
                                      semuaBarang
                                          .where((b) => b.jenis == filterJenis)
                                          .toList();
                                  isPaginationEnabled = true;
                                }
                                pageIndex = 0;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Menampilkan ${paginated.length} dari total ${daftarBarang.length}",
                        ),
                        if (isPaginationEnabled)
                          Text(
                            "Halaman ${pageIndex + 1} / ${(daftarBarang.length / itemsPerPage).ceil()}",
                          ),
                      ],
                    ),
                  ),
                  paginated.isEmpty
                      ? const Expanded(
                        child: Center(child: Text("Tidak ada data barang")),
                      )
                      : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.r),
                          itemCount: paginated.length,
                          itemBuilder: (context, index) {
                            final barang = paginated[index];
                            final now = DateTime.now();
                            final pembelian = barang.waktu;

                            int tahun = now.year - pembelian.year;
                            int bulan = now.month - pembelian.month;
                            int hari = now.day - pembelian.day;

                            if (hari < 0) {
                              bulan -= 1;
                              final prevMonth = DateTime(
                                now.year,
                                now.month,
                                0,
                              );
                              hari += prevMonth.day;
                            }

                            if (bulan < 0) {
                              tahun -= 1;
                              bulan += 12;
                            }

                            final usiaFormatted =
                                "$tahun Tahun $bulan Bulan  $hari Hari";

                            return InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    ModelBarang barangDialog = barang;

                                    String waktuJuall =
                                        barangDialog.waktujual != null
                                            ? DateFormat(
                                              'dd MMM yyyy',
                                            ).format(barangDialog.waktujual!)
                                            : 'Belum Terjual';
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            barangDialog.nama,
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                      content: StatefulBuilder(
                                        builder: (
                                          BuildContext context,
                                          StateSetter setStateDialog,
                                        ) {
                                          return Container(
                                            width: 500,
                                            height: 600,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: 15),
                                                CachedNetworkImage(
                                                  imageUrl:
                                                      '${dotenv.env['API_BASE_URL']}/uploaded_images/${barangDialog.gambar}',
                                                  width: 150.w,
                                                  height: 150.h,
                                                  fit: BoxFit.cover,
                                                ),
                                                SizedBox(height: 30.h),
                                                Table(
                                                  columnWidths: const {
                                                    0: IntrinsicColumnWidth(),
                                                    1: FlexColumnWidth(),
                                                  },
                                                  children: [
                                                    _buildTableRow(
                                                      "Harga Barang",
                                                      "Rp ${barangDialog.harga}",
                                                    ),
                                                    _buildTableRow(
                                                      "Stok Barang",
                                                      "${barangDialog.stok} Pcs",
                                                    ),
                                                    _buildTableRow(
                                                      "Waktu Pembelian",
                                                      "${DateFormat('yyyy-MM-dd').format(barangDialog.waktu)}",
                                                    ),
                                                    _buildTableRow(
                                                      "Jenis Barang",
                                                      "${barangDialog.jenis}",
                                                    ),
                                                    _buildTableRow(
                                                      "Usia Barang",
                                                      usiaFormatted,
                                                    ),
                                                    _buildTableRow(
                                                      "Lokasi Penempatan",
                                                      "${barangDialog.lokasi}",
                                                    ),
                                                    _buildTableRow(
                                                      "Terjual",
                                                      "${barangDialog.terjual}",
                                                    ),
                                                    _buildTableRow(
                                                      "Waktu Penjualan",
                                                      "${waktuJuall}",
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      actions: [
                                        Container(
                                          alignment: Alignment.center,
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors.grey[200],
                                              minimumSize: Size(75, 25),
                                            ),
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: Text(
                                              'Tutup',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 12.r),
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
                                        width: 100.w,
                                        height: 100.w,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) =>
                                                CircularProgressIndicator(),
                                        errorWidget:
                                            (context, url, error) =>
                                                Icon(Icons.broken_image),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              barang.nama,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.sp,
                                              ),
                                            ),
                                            SizedBox(height: 6.h),
                                            Text(
                                              "Harga Barang: Rp${barang.harga}",
                                            ),
                                            Text(
                                              "Stok Barang: ${barang.stok} Pcs",
                                            ),
                                            Text(
                                              "Jenis Barang: ${barang.jenis}",
                                            ),
                                            Text(
                                              "Waktu Pembelian: ${DateFormat('yyyy-MM-dd').format(DateTime.parse('${barang.waktu}'))}",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  if (isPaginationEnabled)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 16.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: pageIndex > 0 ? prevPage : null,
                            child: const Text("Sebelumnya"),
                          ),
                          Text(
                            "Halaman ${pageIndex + 1} dari ${(daftarBarang.length / itemsPerPage).ceil()}",
                          ),
                          ElevatedButton(
                            onPressed:
                                (pageIndex + 1) * itemsPerPage <
                                        daftarBarang.length
                                    ? nextPage
                                    : null,
                            child: const Text("Berikutnya"),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  Widget buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Function() onTap,
  }) {
    return Padding(
      padding: EdgeInsets.all(10.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, size: 22.sp),
          title: Text(title, style: TextStyle(fontSize: 14.sp)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFFFFFFFF),
      width: 200.w,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Container(
              width: double.infinity,
              height: 150.h,
              child: Center(
                child: Image.asset(
                  'data/koptel.png',
                  width: 300.w,
                  height: 240.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          buildDrawerItem(
            context,
            icon: Icons.all_inbox,
            title: "Semua Barang",
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Dashboard()),
              );
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.add,
            title: "Tambah Barang",
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AddPage()),
              );
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.update,
            title: "Update Barang",
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Update()),
              );
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.delete_forever,
            title: "Hapus Barang",
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Delete()),
              );
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.sell,
            title: "Jual Barang",
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => Jual()),
              );
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.history,
            title: "Histori Penjualan",
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HistoriPage()),
              );
            },
          ),
          buildDrawerItem(
            context,
            icon: Icons.download,
            title: "Download Excel",
            onTap: () async {
              final baseUrl = dotenv.env['API_BASE_URL'];
              if (baseUrl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("API_BASE_URL tidak ditemukan di .env"),
                  ),
                );
                return;
              }
              final url = "$baseUrl/barang/laporan/export-excel";
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (_) => const Center(child: CircularProgressIndicator()),
                );

                final dir = await getTemporaryDirectory();
                final filePath = "${dir.path}/laporan_barang.xlsx";
                final token = await AuthService.getToken();
                final dio = Dio();
                dio.options.headers['Authorization'] = 'Bearer $token';
                final response = await dio.download(url, filePath);

                Navigator.of(context).pop();

                if (response.statusCode == 200) {
                  await OpenFile.open(filePath);
                } else if (response.statusCode == 401) {
                  await AuthService.clearToken();
                  Navigator.of(
                    context,
                  ).pushReplacement(MaterialPageRoute(builder: (_) => Login()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal mengunduh file")),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error")));
              }
            },
          ),
          SizedBox(height: 100.h),
          buildDrawerItem(
            context,
            icon: Icons.logout,
            title: "Logout",
            onTap: () async {
              await AuthService.clearToken();
              Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => Login()));
            },
          ),
        ],
      ),
    );
  }
}
