import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ovopay/app/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovopay/core/data/models/global/qr_code/scan_qr_code_response_model.dart';
import 'package:ovopay/core/data/models/global/response_model/response_model.dart';
import 'package:ovopay/core/data/models/user/user_model.dart';
import 'package:ovopay/core/data/repositories/account/profile_repo.dart';
import 'package:ovopay/environment.dart';

import '../../../../core/data/models/profile/profile_response_model.dart';
import '../../../../core/data/services/service_exporter.dart';
import '../../../../core/utils/util_exporter.dart';

class MyQrCodeController extends GetxController {
  /* ----------  REPO  ---------- */
  final ProfileRepo profileRepo = ProfileRepo();

  /* ----------  UI FLAGS  ---------- */
  bool isLoading = false;
  bool isDownloadLoading = false;
  bool isScanningQrCodeLoading = false;
  bool isQrCodeLoginLoading = false;

  /* ----------  QR CODE  ---------- */
  String qrCodeLink = '';

  /* ----------  VIRTUAL ACCOUNT  ---------- */
  String virtualAccount = '';
  String virtualBank = '';
  String virtualAcctName = '';

  /* =========================================================
   *  1.  FETCH VIRTUAL ACCOUNT - FIXED VERSION
   * =======================================================*/
  Future<void> getVirtualAccount() async {
    isLoading = true;
    update();

    try {
      final token = SharedPreferenceService.getString(
          SharedPreferenceService.accessTokenKey);
      if (token == null || token.isEmpty) {
        CustomSnackBar.error(errorList: ['User not logged in']);
        isLoading = false;
        update();
        return;
      }

      final uri = Uri.parse('https://pay.edubest.com.ng/api/user/virtual-account');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🔐 TOKEN  : ${token.substring(0, 20)}...');
      print('📡 GET    : $uri');
      print('📡 HEADERS: $headers');

      final res = await http.get(uri, headers: headers);

      print('📩 STATUS : ${res.statusCode}');
      print('📩 BODY   : ${res.body}');

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;

        // DEBUG: Print all keys to see the actual structure
        print('🔍 API RESPONSE KEYS: ${map.keys.toList()}');

        if (map['status'] == 'success') {
          // FIX: Access the fields directly from root, not from 'data'
          virtualAccount = map['account_number']?.toString() ?? '';
          virtualBank = map['bank_name']?.toString() ?? '';

          // Use user's name since API doesn't provide account_name
          virtualAcctName = SharedPreferenceService.getUserFullName();

          print('✅ VIRTUAL ACCOUNT LOADED:');
          print('✅ Account: $virtualAccount');
          print('✅ Bank: $virtualBank');
          print('✅ Name: $virtualAcctName');

          CustomSnackBar.success(successList: ['Account details loaded successfully']);
        } else {
          CustomSnackBar.error(
              errorList: [map['message']?.toString() ?? 'Failed to load virtual account']);
        }
      } else {
        CustomSnackBar.error(errorList: ['Server error ${res.statusCode}']);
      }
    } catch (e) {
      printE(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    } finally {
      isLoading = false;
      update();
    }
  }

  /* =========================================================
   *  2.  QR-CODE IMAGE URL
   * =======================================================*/
  Future<void> getMyQrCodeData() async {
    isLoading = true;
    update();

    try {
      final ResponseModel responseModel = await profileRepo.getMyQrCodeData();

      if (responseModel.statusCode == 200) {
        final ProfileResponseModel model = ProfileResponseModel.fromJson(
          responseModel.responseJson,
        );

        if (model.status.toString() == 'success') {
          qrCodeLink = model.data?.qrCode ?? '';
          print('✅ QR Code Loaded: $qrCodeLink');
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e);
    } finally {
      isLoading = false;
      update();
    }
  }

  /* =========================================================
   *  3.  DOWNLOAD HELPERS
   * =======================================================*/
  Future<void> downloadAttachment(String url, String extension) async {
    isDownloadLoading = true;
    update();

    try {
      if (await MyUtils().checkAndRequestStoragePermission()) {
        final Directory downloadsDirectory =
        await MyUtils.getDefaultDownloadDirectory();
        final fileName =
            '${Environment.appName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final downloadPath = '${downloadsDirectory.path}/$fileName';

        final ResponseModel responseModel =
        await profileRepo.downloadMyQrCodeData();
        final ResponseModel downloadModel = await ApiService.downloadFile(
          byteData: responseModel.responseJson,
          savePath: downloadPath,
        );
        await MyUtils().openFile(downloadPath, extension);
        CustomSnackBar.success(successList: [downloadModel.message]);
      } else {
        CustomSnackBar.error(
            errorList: ['Storage permission is required to download files.']);
      }
    } catch (e) {
      printE(e.toString());
      CustomSnackBar.error(errorList: ['Failed to download file: $e']);
    } finally {
      isDownloadLoading = false;
      update();
    }
  }

  /* =========================================================
   *  4.  SCAN / LOGIN HELPERS
   * =======================================================*/
  String scanUserType = '';
  UserModel? existUserModel;

  Future<ScanQrCodeResponseModel> scanQrCodeDataFromServer({
    String inputText = '',
  }) async {
    isScanningQrCodeLoading = true;
    update();

    try {
      final ResponseModel responseModel =
      await profileRepo.scanQrCodeData(code: inputText);

      if (responseModel.statusCode == 200) {
        final scanQrCodeResponseModel = scanQrCodeResponseModelFromJson(
          jsonEncode(responseModel.responseJson),
        );
        if (scanQrCodeResponseModel.status == 'success') {
          scanUserType = scanQrCodeResponseModel.data?.userType ?? '';
          existUserModel = scanQrCodeResponseModel.data?.userData;
          return scanQrCodeResponseModel;
        } else {
          CustomSnackBar.error(
            errorList:
            scanQrCodeResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    } finally {
      isScanningQrCodeLoading = false;
      update();
    }
    return ScanQrCodeResponseModel();
  }

  Future<bool> qrCodeLogin({String inputText = ''}) async {
    isQrCodeLoginLoading = true;
    update();

    try {
      final ResponseModel responseModel =
      await profileRepo.qrCodeLogin(code: inputText);

      if (responseModel.statusCode == 200) {
        final scanQrCodeResponseModel = scanQrCodeResponseModelFromJson(
          jsonEncode(responseModel.responseJson),
        );
        if (scanQrCodeResponseModel.status == 'success') {
          CustomSnackBar.success(
            successList:
            scanQrCodeResponseModel.message ?? [MyStrings.requestSuccess],
          );
          return true;
        } else {
          CustomSnackBar.error(
            errorList:
            scanQrCodeResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    } finally {
      isQrCodeLoginLoading = false;
      update();
    }
    return false;
  }
}