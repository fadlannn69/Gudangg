import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gudkoptell/registry/login.dart';
import 'package:gudkoptell/registry/register.dart';
import 'package:gudkoptell/registry/face_login.dart';
import 'package:gudkoptell/registry/face_regis.dart';
import 'package:gudkoptell/home/dashboard.dart';
import 'package:gudkoptell/http/http_user.dart';
import 'package:gudkoptell/http/http_barang.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Gagal load .env: $e");
  }
  UserApiService.init();
  BarangApiService.init();
  runApp(const GudkopTelApp());
}

class GudkopTelApp extends StatelessWidget {
  const GudkopTelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Gudang KOPTEL",
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
          ),
          initialRoute: Dashboard.routeName,
          routes: {
            Login.routeName: (context) => Login(),
            Register.routeName: (context) => Register(),
            FaceLogin.routeName: (context) => FaceLogin(),
            FaceRegis.routeName: (context) => FaceRegis(),
            Dashboard.routeName: (context) => Dashboard(),
          },
        );
      },
    );
  }
}
