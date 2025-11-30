import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (await Permission.storage.request().isDenied) {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }
}
