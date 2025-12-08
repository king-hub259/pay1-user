import 'dart:async';
import 'package:flutter/services.dart';          // PlatformException
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import 'package:ovopay/app/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovopay/core/data/models/profile/profile_response_model.dart';
import 'package:ovopay/core/data/repositories/biometric/biometric_repo.dart';
import 'package:ovopay/core/data/services/shared_pref_service.dart';
import '../../../../../core/utils/util_exporter.dart';

class BioMetricController extends GetxController {
  /* ---------- local_auth ---------- */
  final LocalAuthentication _auth = LocalAuthentication();

  /* ---------- repo / UI ---------- */
  final BiometricRepo biometricRepo = BiometricRepo();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();

  /* ---------- observable ---------- */
  final RxBool isLoading = false.obs;
  final RxBool isDeviceSupportBiometric = false.obs;
  final RxBool isBiometricEnabled = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;
  final RxBool hasFaceID = false.obs;
  final RxBool hasFingerprint = false.obs;
  final RxBool isShowBioMetricAccountPinBox = false.obs;
  final RxBool isPinValidateLoading = false.obs;

  /* ---------- life-cycle ---------- */
  @override
  void onInit() {
    super.onInit();
    loadBiometricPreference();
    checkAvailableBiometrics();
  }

  /* ---------- preferences ---------- */
  Future<void> loadBiometricPreference() async {
    isBiometricEnabled.value = SharedPreferenceService.getBioMetricStatus();
  }

  /* ---------- availability ---------- */
  Future<void> checkAvailableBiometrics() async {
    try {
      isDeviceSupportBiometric.value = await _auth.isDeviceSupported();
      if (!isDeviceSupportBiometric.value) return;

      final List<BiometricType> biometrics =
      await _auth.getAvailableBiometrics();
      availableBiometrics.assignAll(biometrics);
      hasFaceID.value = biometrics.contains(BiometricType.face);
      hasFingerprint.value = biometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get biometric availability: $e');
    }
  }

  /* ---------- toggle ---------- */
  Future<void> toggleBiometric(bool enable) async {
    if (enable) {
      final ok = await _authenticateWithBiometrics();
      if (ok) {
        await SharedPreferenceService.setBioMetricStatus(true);
        isBiometricEnabled.value = true;
      }
    } else {
      await SharedPreferenceService.setBioMetricStatus(false);
      isBiometricEnabled.value = false;
    }
  }

  /* ---------- enable / disable ---------- */
  Future<void> enableBiometric({required VoidCallback onSuccess}) async {
    final ok = await _authenticateWithBiometrics();
    if (ok) {
      await setBioMetric(
        onSuccess: () async {
          await SharedPreferenceService.setBioMetricStatus(true);
          isShowBioMetricAccountPinBox.value = false;
          isBiometricEnabled.value = true;
          onSuccess();
        },
        onDisableSuccess: () {},
      );
    }
  }

  Future<void> disableBiometric({required VoidCallback onSuccess}) async {
    final ok = await _authenticateWithBiometrics();
    if (ok) {
      await setBioMetric(
        onSuccess: () {},
        onDisableSuccess: () async {
          await SharedPreferenceService.setBioMetricStatus(false);
          isBiometricEnabled.value = false;
          isShowBioMetricAccountPinBox.value = false;
          onSuccess();
        },
      );
    }
  }

  /* ---------- login flow ---------- */
  Future<void> checkBiometric({
    required VoidCallback onSuccess,
    bool fromLogin = false,
  }) async {
    final ok = await _authenticateWithBiometrics(fromLogin: fromLogin);
    if (ok) onSuccess();
  }

  /* ---------- private auth ---------- */
  Future<bool> _authenticateWithBiometrics({bool fromLogin = false}) async {
    try {
      return await _auth.authenticate(
        localizedReason: fromLogin
            ? 'Please provide your device pin to login'
            : 'Please authenticate to enable biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:          // ← official constant
          CustomSnackBar.error(errorList: ['Biometrics is not available']);
          return false;
        case auth_error.notEnrolled:           // ← official constant
          CustomSnackBar.error(errorList: ['Biometrics is not enrolled']);
          return false;
        default:
          printE('Authentication error: $e');
          return false;
      }
    } catch (e) {
      printE('Unexpected error: $e');
      return false;
    }
  }

  /* ---------- PIN box ---------- */
  void toggleIsShowAccountPinBox() =>
      isShowBioMetricAccountPinBox.toggle();

  /* ---------- API calls ---------- */
  Future<void> setBioMetric({
    required VoidCallback onSuccess,
    required VoidCallback onDisableSuccess,
  }) async {
    try {
      isPinValidateLoading.value = true;

      // Step-1: validate PIN
      final pinResponse = await biometricRepo.checkPinOfAccount(
        pin: pinCodeController.text.trim(),
      );
      if (pinResponse.statusCode != 200) {
        _handleError([pinResponse.message]);
        return;
      }

      final pinCheckResponse =
      ProfileResponseModel.fromJson(pinResponse.responseJson);
      if (pinCheckResponse.status?.toLowerCase() !=
          AppStatus.SUCCESS.toLowerCase()) {
        _handleError(pinCheckResponse.message ?? []);
        return;
      }

      pinCodeController.clear();

      // Step-2: success callbacks
      onSuccess();
      onDisableSuccess();
    } catch (e) {
      CustomSnackBar.error(errorList: [MyStrings.requestFail]);
    } finally {
      isPinValidateLoading.value = false;
    }
  }

  /* ---------- helper ---------- */
  void _handleError(List<String>? errorMessage) {
    CustomSnackBar.error(errorList: errorMessage ?? [MyStrings.requestFail]);
    isPinValidateLoading.value = false;
  }
}