import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/home/dashboard.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddPage extends StatefulWidget {
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();
  final TextEditingController stokController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController waktuController = TextEditingController();

  String? selectedJenis;
  bool _isLoading = false;
  File? _imageFile;
  String? _savedImagePath;

  @override
  void dispose() {
    namaController.dispose();
    hargaController.dispose();
    stokController.dispose();
    lokasiController.dispose();
    waktuController.dispose();
    super.dispose();
  }

  Future<File?> pickAndCompressImage() async {
    final picker = ImagePicker();

    try {
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return null;

      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, 'compressed_${picked.name}');

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        minWidth: 400,
        minHeight: 400,
        quality: 42,
      );

      if (compressedXFile == null) {
        print("❌ Gagal mengompres gambar, menggunakan file asli.");
        return File(picked.path);
      }

      final compressedFile = File(compressedXFile.path);
      print("✅ Kompresi berhasil: ${compressedFile.lengthSync()} bytes");
      return compressedFile;
    } catch (e) {
      print("❌ Error saat memilih atau mengompres gambar: $e");
      return null;
    }
  }

  Future<void> _ambilGambar() async {
    setState(() => _isLoading = true);

    final file = await pickAndCompressImage();
    if (file == null) {
      setState(() => _isLoading = false);
      return;
    }

    final ext = path.extension(file.path).toLowerCase();
    if (!(ext == '.jpg' || ext == '.jpeg')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hanya file .jpg atau .jpeg yang diperbolehkan"),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(file.path);
    final savedImage = await file.copy('${appDir.path}/$fileName');

    setState(() {
      _imageFile = savedImage;
      _savedImagePath = savedImage.path;
      _isLoading = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_image_path', _savedImagePath!);
  }

  Future<void> _submitForm() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ambil gambar dulu")));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final dio = Dio(
        BaseOptions(
          baseUrl: dotenv.env['API_BASE_URL'] ?? '',
          headers: {'Authorization': 'Bearer $token'},
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final formData = FormData.fromMap({
        'nama': namaController.text,
        'harga': int.tryParse(hargaController.text) ?? 0,
        'stok': int.tryParse(stokController.text) ?? 0,
        'lokasi': lokasiController.text,
        'waktu': waktuController.text,
        'jenis': selectedJenis ?? '',
        'gambar': await MultipartFile.fromFile(
          _imageFile!.path,
          filename: path.basename(_imageFile!.path),
        ),
      });

      final response = await dio.post('/barang/tambah', data: formData);
      print("Upload berhasil: ${response.data}");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Barang berhasil ditambahkan")));

      prefs.remove('last_image_path');
      if (_savedImagePath != null && File(_savedImagePath!).existsSync()) {
        File(_savedImagePath!).delete();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard()),
      );
    } on DioException catch (e) {
      print("Upload gagal: ${e.response?.data}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: ${e.message}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(left: 60.w),
          child: Text(
            "Tambah Barang",
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
      ),
      drawer: MyDrawer(),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 16.h),
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.file(_imageFile!, height: 200.h),
                  ),
                ElevatedButton(
                  onPressed: _ambilGambar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    fixedSize: Size(175.w, 30.h),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.black),
                      SizedBox(width: 5.w),
                      Text(
                        "Ambil Gambar Barang !!",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5.h),
                _buildTextField(namaController, "Nama Barang", Icons.abc),
                _buildTextField(
                  hargaController,
                  "Harga Barang",
                  Icons.price_change,
                  isNumber: true,
                ),
                _buildTextField(
                  stokController,
                  "Stok Barang",
                  Icons.inventory,
                  isNumber: true,
                ),
                _buildTextField(
                  lokasiController,
                  "Lokasi Penempatan Barang",
                  Icons.location_on,
                ),
                _buildDatePicker(context),
                _buildDropdownJenis(),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child:
                        _isLoading
                            ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                            : Text(
                              "Kirim!!",
                              style: TextStyle(
                                fontSize: 20.sp,
                                color: Colors.black,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return "$hint wajib diisi";
          if (isNumber && int.tryParse(value) == null)
            return "$hint harus berupa angka";
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: waktuController,
        readOnly: true,
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            waktuController.text =
                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          }
        },
        validator:
            (value) =>
                (value == null || value.isEmpty) ? "Tanggal wajib diisi" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.calendar_today),
          hintText: "Pilih Tanggal Pembelian",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    );
  }

  Widget _buildDropdownJenis() {
    return DropdownButtonFormField<String>(
      value: selectedJenis,
      items: const [
        DropdownMenuItem(value: "Barang Asset", child: Text("Barang Asset")),
        DropdownMenuItem(
          value: "Barang Habis Pakai",
          child: Text("Barang Habis Pakai"),
        ),
      ],
      onChanged: (value) => setState(() => selectedJenis = value),
      validator: (value) => value == null ? 'Jenis barang harus dipilih' : null,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category),
        hintText: "Pilih Jenis Barang",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }
}
