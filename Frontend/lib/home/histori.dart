import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/auth_service.dart';
import 'package:gudkoptell/model/model_barang.dart';
import 'package:intl/intl.dart';

class HistoriPage extends StatefulWidget {
  const HistoriPage({Key? key}) : super(key: key);

  @override
  State<HistoriPage> createState() => _HistoriPageState();
}

class _HistoriPageState extends State<HistoriPage> {
  late Future<List<ModelHistori>> _histori;

  final Dio dio = Dio();

  Future<List<ModelHistori>> fetchHistori() async {
    final token = await AuthService.getToken();
    final url = "${dotenv.env['API_BASE_URL']}/barang/histori";

    final response = await dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      List jsonData = response.data;
      return jsonData.map((e) => ModelHistori.fromJson(e)).toList();
    } else {
      throw Exception("Gagal mengambil histori penjualan");
    }
  }

  @override
  void initState() {
    super.initState();
    _histori = fetchHistori();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: 40.w),
          child: Text(
            "Histori Penjualan",
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ),
      body: FutureBuilder<List<ModelHistori>>(
        future: _histori,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return Center(child: Text("Belum ada histori"));
          }

          return ListView.separated(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return ListTile(
                tileColor: Colors.grey[300],
                leading: Icon(Icons.history),
                title: Text(item.nama),
                subtitle: Text(
                  "Terjual: ${item.terjual} | Total: Rp${item.totalHarga}",
                ),
                trailing: Text(DateFormat('dd/MM/yyyy').format(item.waktujual)),
              );
            },
            separatorBuilder: (context, index) => SizedBox(height: 5),
          );
        },
      ),
    );
  }
}
