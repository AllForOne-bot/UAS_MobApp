// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:tubes_mobapp/Menu.dart';

// class AuthService {
//   final SupabaseClient supabase = Supabase.instance.client;

//   // Tipe pengguna
//   static const String userTypeAdmin = 'Dosen';
//   static const String userTypeUser = 'Mahasiswa';

//   /// Login: Proses login menggunakan Supabase auth dan simpan userType dari metadata
//   Future<void> login(
//     BuildContext context,
//     String email,
//     String password,
//   ) async {
//     try {
//       final response = await supabase.auth.signInWithPassword(
//         email: email,
//         password: password,
//       );

//       if (response.session != null && response.user != null) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setBool('isLoggedIn', true);

//         // Mengambil metadata pengguna dari Supabase Auth
//         final userMetadata = response.user?.userMetadata;
//         final userType = userMetadata?['user_type'] as String? ?? userTypeUser;
//         final displayName = userMetadata?['displayName'] as String? ?? '';

//         await prefs.setString('userType', userType);
//         await prefs.setString('displayName', displayName);

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const Menu()),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Login gagal: ${e.toString()}")));
//     }
//   }

//   /// Registrasi: Simpan displayName dan user_type sesuai parameter
//   Future<bool> signUp(
//     BuildContext context,
//     String email,
//     String password,
//     String displayName, {
//     required String userType,
//   }) async {
//     try {
//       final response = await supabase.auth.signUp(
//         email: email,
//         password: password,
//         data: {'displayName': displayName, 'user_type': userType},
//       );

//       if (response.user != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Akun berhasil dibuat! Silakan login.")),
//         );
//         return true;
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Sign up gagal: ${e.toString()}")));
//     }
//     return false;
//   }

//   /// Logout: Reset SharedPreferences dan kembali ke halaman login
//   // Future<void> logout(BuildContext context) async {
//   //   await supabase.auth.signOut();
//   //   final prefs = await SharedPreferences.getInstance();
//   //   await prefs.setBool('isLoggedIn', false);
//   //   await prefs.remove('userType');
//   //   await prefs.remove('displayName');
//   //   Navigator.pushReplacement(
//   //     context,
//   //     MaterialPageRoute(builder: (_) => const LoginKonektor()),
//   //   );
//   // }

//   /// Update profil (hanya displayName untuk user biasa)
//   Future<void> updateUserProfile({required String displayName}) async {
//     try {
//       await supabase.auth.updateUser(
//         UserAttributes(data: {'displayName': displayName}),
//       );
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('displayName', displayName);
//     } catch (e) {
//       throw Exception('Gagal update profil: $e');
//     }
//   }

//   /// Kirim OTP email untuk reset password (user biasa)
//   Future<void> sendOtpEmail(BuildContext context, String email) async {
//     try {
//       await supabase.auth.resetPasswordForEmail(email);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Kode OTP telah dikirim ke email Anda")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Gagal mengirim kode OTP: ${e.toString()}")),
//       );
//     }
//   }

//   // /// Reset password via link
//   // Future<void> resetPassword(BuildContext context, String email) async {
//   //   try {
//   //     await supabase.auth.resetPasswordForEmail(email);
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Link reset password telah dikirim!")),
//   //     );
//   //     Navigator.pop(context);
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text("Gagal reset password: ${e.toString()}")),
//   //     );
//   //   }
//   // }

//   /// Verifikasi OTP manual
//   Future<bool> verifyOtp(String email, String token) async {
//     try {
//       await supabase.auth.verifyOTP(
//         type: OtpType.recovery,
//         email: email,
//         token: token,
//       );
//       return true;
//     } catch (e) {
//       print('Error verify OTP: $e');
//       return false;
//     }
//   }

//   /// Placeholder untuk halaman reset token manual
//   sendResetToken(BuildContext context, String email) {}
// }
