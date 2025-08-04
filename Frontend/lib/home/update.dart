import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/home/dashboard.dart';
import 'package:gudkoptell/http/http_barang.dart';
import 'package:gudkoptell/model/model_barang.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Update extends StatefulWidget {
  const Update({super.key});

  @override
  State<Update> createState() => _UpdateState();
}

class _UpdateState extends State<Update> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: 60.w),
          child: Text(
            "Update Barang",
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
      ),
      drawer: MyDrawer(),
      body: const UpdateBarangScreen(),
    );
  }
}

class UpdateBarangScreen extends StatefulWidget {
  const UpdateBarangScreen({super.key});

  @override
  State<UpdateBarangScreen> createState() => _UpdateBarangScreenState();
}

class _UpdateBarangScreenState extends State<UpdateBarangScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();
  final TextEditingController stokController = TextEditingController();

  bool isLoading = false;

  Future<void> updateBarang() async {
    final nama = namaController.text.trim();
    final harga = int.tryParse(hargaController.text.replaceAll('.', ''));
    final stok = int.tryParse(stokController.text.trim());

    if (nama.isEmpty || harga == null || stok == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Semua field harus diisi dengan benar.",
            style: TextStyle(fontSize: 14.sp),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Yakin ingin memperbarui barang ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Update"),
              ),
            ],
          ),
    );

    if (konfirmasi != true) return;

    setState(() => isLoading = true);

    final barang = BarangUpdate(harga: harga, stok: stok);
    final success = await BarangApiService.updateBarang(nama, barang);

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Barang berhasil diupdate!" : "Gagal update barang.",
          style: TextStyle(fontSize: 14.sp),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => Dashboard()));
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    hargaController.dispose();
    stokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            TextField(
              controller: namaController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: "Nama Barang",
                labelStyle: TextStyle(fontSize: 14.sp),
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: "Harga Baru",
                labelStyle: TextStyle(fontSize: 14.sp),
                prefixIcon: Icon(Icons.price_change),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),

            SizedBox(height: 16.h),
            TextField(
              controller: stokController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: "Stok Baru",
                labelStyle: TextStyle(fontSize: 14.sp),
                prefixIcon: Icon(Icons.storage),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateBarang,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child:
                    isLoading
                        ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                        : Text("Kirim", style: TextStyle(fontSize: 18.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('.', '');
    if (text.isEmpty) return newValue;

    final number = int.parse(text);
    final newText = formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
