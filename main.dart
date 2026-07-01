// lib/services/file_helper_mobile.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveExcelFile(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(bytes);
}
