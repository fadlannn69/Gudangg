import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gudkoptell/model/model_user.dart';
import 'package:gudkoptell/registry/face_login.dart';
import 'package:gudkoptell/registry/register.dart';
import '../http/http_user.dart';

class Login extends StatefulWidget {
  static const routeName = '/login';
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _obscureText = true;
  bool _isLoading = false;

  final nikController = TextEditingController();
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

  Future<void> _handleLogin() async {
    final nik = int.tryParse(nikController.text.trim());
    final password = passwordController.text.trim();

    if (nik == null || password.isEmpty) {
      _showSnackbar("NIK dan Password wajib diisi");
      return;
    }

    setState(() => _isLoading = true);

    final user = UserModelLogin(nik: nik, password: password);
    bool success = await UserApiService.loginUser(user);

    setState(() => _isLoading = false);

    if (success) {
      _showSnackbar("Login berhasil", bgColor: Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FaceLogin()),
      );
    } else {
      _showSnackbar("Login gagal. Cek kembali NIK dan password.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFFFF),
        title: Center(
          child: Image.asset('data/koptel.png', width: 200.w, height: 50.h),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Text(
              "Login Page",
              style: TextStyle(fontSize: 45.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Image.asset('data/logo.png', width: 150.w, height: 150.h),
            SizedBox(height: 30.h),

            TextField(
              controller: nikController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: Icon(Icons.key),
                hintText: "Masukkan NIK Telkom Group",
              ),
            ),
            SizedBox(height: 15.h),

            TextField(
              controller: passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
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
            SizedBox(height: 30.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                            color: Colors.white70,
                            strokeWidth: 3,
                          ),
                        )
                        : Text(
                          "Login!",
                          style: TextStyle(
                            fontSize: 22.sp,
                            color: Colors.black,
                          ),
                        ),
              ),
            ),

            SizedBox(height: 10.h),

            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Register()),
                );
              },
              child: Text(
                "Gak Punya Akun?? , Register Disini!!",
                style: TextStyle(fontSize: 14.sp, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
