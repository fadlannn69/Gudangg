import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/registry/login.dart';
import '../model/model_user.dart';
import '../http/http_user.dart';

class Register extends StatefulWidget {
  static const routeName = '/register';
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscureText = true;
  bool _isLoading = false;

  final nikController = TextEditingController();
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _showSnackbar(String msg, {Color bgColor = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bgColor));
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    final nik = int.tryParse(nikController.text.trim());
    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (nik == null || nama.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar("Semua field harus diisi");
      return;
    }

    setState(() => _isLoading = true);

    final user = UserModelRegister(
      nik: nik,
      nama: nama,
      email: email,
      password: password,
    );

    final success = await UserApiService.registerUser(user);

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar("Registrasi berhasil!", bgColor: Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } else {
      _showSnackbar("Registrasi gagal. Coba lagi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Center(
          child: Image.asset('data/koptel.png', width: 150.w, height: 50.h),
        ),
        backgroundColor: Color(0xFFFFFFFF),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            Image.asset('data/logo.png', width: 200.w, height: 200.h),
            SizedBox(height: 20.h),
            Text(
              "Register Page",
              style: TextStyle(fontSize: 32.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 35.h),

            TextField(
              controller: nikController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                hintText: "Masukkan NIK Telkom Group",
              ),
            ),
            SizedBox(height: 10.h),

            TextField(
              controller: namaController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: "Masukkan Nama",
              ),
            ),
            SizedBox(height: 10.h),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                hintText: "Masukkan Email",
              ),
            ),
            SizedBox(height: 10.h),

            TextField(
              controller: passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                hintText: "Masukkan Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: _toggleVisibility,
                ),
              ),
            ),
            SizedBox(height: 20.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                          "Register Now!!",
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
    );
  }
}
