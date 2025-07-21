import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../http/http_user.dart';

class FaceRegis extends StatefulWidget {
  static const routeName = '/face_regis';

  @override
  _FaceRegisState createState() => _FaceRegisState();
}

class _FaceRegisState extends State<FaceRegis> {
  final TextEditingController _nikController = TextEditingController();
  File? _imageFile;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<File> convertToJpg(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception("Gagal decode gambar");

    final jpgBytes = img.encodeJpg(image, quality: 90);
    final dir = await getTemporaryDirectory();
    final jpgPath = path.join(dir.path, 'converted.jpg');

    return File(jpgPath).writeAsBytes(jpgBytes);
  }

  Future<void> _registerFace() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Harap isi NIK dan ambil foto terlebih dahulu"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      File jpgImage = await convertToJpg(_imageFile!);

      final response = await UserApiService.registerFace(
        nik: nik,
        image: jpgImage,
      );

      if (response != null && response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pendaftaran wajah berhasil!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gambar Register Buram, Register Ulang"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gambar Buram, Pindah ke tempat lebih terang"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset('data/koptel.png', width: 180.w, height: 50.h),
        ),
        backgroundColor: Color(0xFFFFFFFFF),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Register Face!!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 40.sp),
            ),
            SizedBox(height: 30.h),
            Image.asset('data/face.png', width: 140.w, height: 140.h),
            SizedBox(height: 30.h),
            TextField(
              controller: _nikController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: Icon(Icons.key),
                hintText: "Masukkan NIK Telkom Group",
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _getImageFromCamera,
              icon: Icon(Icons.camera_alt, color: Colors.black),
              label: Text(
                'Ambil Foto dari Kamera',
                style: TextStyle(fontSize: 20.sp, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                backgroundColor: Colors.grey[300],
              ),
            ),
            SizedBox(height: 20.h),
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(_imageFile!, height: 200.h),
              ),
            SizedBox(height: 30.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerFace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : Text(
                          'Daftarkan Wajah',
                          style: TextStyle(
                            fontSize: 22.sp,
                            color: Colors.black,
                          ),
                        ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
