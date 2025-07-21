import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/home/dashboard.dart';
import 'package:gudkoptell/http/http_barang.dart';
import 'package:gudkoptell/model/model_barang.dart';

class Delete extends StatefulWidget {
  const Delete({super.key});

  @override
  State<Delete> createState() => _DeleteState();
}

class _DeleteState extends State<Delete> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: 60.w),
          child: Text(
            "Hapus Barang",
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
      ),
      drawer: MyDrawer(),
      body: const HapusBarang(),
    );
  }
}

class HapusBarang extends StatefulWidget {
  const HapusBarang({super.key});

  @override
  State<HapusBarang> createState() => _HapusBarangState();
}

class _HapusBarangState extends State<HapusBarang> {
  final TextEditingController namaController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    namaController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Nama barang harus diisi")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Yakin ingin menghapus barang ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Hapus"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final barang = HapussBarang(nama: namaController.text.trim());
    bool success = await BarangApiService.deleteBarang(barang);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Barang berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => Dashboard()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menghapus barang"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
      child: Column(
        children: [
          SizedBox(height: 30.h),
          TextField(
            controller: namaController,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              prefixIcon: Icon(Icons.delete, size: 20.sp),
              hintText: "Masukkan Nama Barang",
              hintStyle: TextStyle(fontSize: 14.sp),
            ),
          ),
          SizedBox(height: 30.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleDelete,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child:
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Kirim", style: TextStyle(fontSize: 18.sp)),
            ),
          ),
        ],
      ),
    );
  }
}
