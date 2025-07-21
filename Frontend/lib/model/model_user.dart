class UserModelRegister {
  final int nik;
  final String nama;
  final String email;
  final String password;

  UserModelRegister({
    required this.nik,
    required this.nama,
    required this.email,
    required this.password,
  });

  factory UserModelRegister.fromJson(Map<String, dynamic> json) {
    return UserModelRegister(
      nik: json['nik'],
      nama: json['nama'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {"nik": nik, "nama": nama, "email": email, "password": password};
  }
}

class UserModelLogin {
  final int nik;
  final String password;

  UserModelLogin({required this.nik, required this.password});

  factory UserModelLogin.fromJson(Map<String, dynamic> json) {
    return UserModelLogin(nik: json['nik'], password: json['password']);
  }

  Map<String, dynamic> toJson() {
    return {"nik": nik, "password": password};
  }
}
