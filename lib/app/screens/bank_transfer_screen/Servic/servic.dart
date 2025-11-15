import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();
  final _box = GetStorage();

  String? get token => _box.read<String>('token');
  Future<void> saveToken(String t) => _box.write('token', t);
  Future<void> logout() => _box.remove('token');
}