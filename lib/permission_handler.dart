import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Minta izin untuk tulis storage/external-storage.
  /// Mengembalikan true jika granted, false jika ditolak.
  static Future<bool> requestStorage(BuildContext context) async {
    // Tangkap messenger *sebelum* await agar safe
    final messenger = ScaffoldMessenger.of(context);

    // Pilih permission: di Android gunakan MANAGE_EXTERNAL_STORAGE,
    // di platform lain pakai STORAGE
    final permission = Platform.isAndroid
        ? Permission.manageExternalStorage
        : Permission.storage;

    // Minta izin
    final status = await permission.request();
    final granted = status.isGranted;

    // Tampilkan hasil
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          granted
            ? 'Izin penyimpanan diberikan'
            : 'Izin penyimpanan tidak diberikan!',
        ),
      ),
    );

    return granted;
  }
}
