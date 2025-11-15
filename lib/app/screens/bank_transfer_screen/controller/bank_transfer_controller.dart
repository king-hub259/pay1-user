import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ovopay/app/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovopay/core/data/models/global/charges/global_charge_model.dart';
import 'package:ovopay/core/data/models/global/formdata/dynamic_fom_submitted_value_model.dart';
import 'package:ovopay/core/data/models/global/response_model/response_model.dart';
import 'package:ovopay/core/data/models/kyc/kyc_response_model.dart';
import 'package:ovopay/core/data/models/modules/bank_transfer/bank_transfer_add_new_bank_submit_response_model.dart';
import 'package:ovopay/core/data/models/modules/bank_transfer/bank_transfer_history_response_model.dart';
import 'package:ovopay/core/data/models/modules/bank_transfer/bank_transfer_info_response_model.dart';
import 'package:ovopay/core/data/models/modules/bank_transfer/bank_transfer_submit_response_model.dart';
import 'package:ovopay/core/data/models/modules/global/module_transaction_model.dart';
import 'package:ovopay/core/data/repositories/modules/bank_transfer/bank_transfer_repo.dart';
import '../../../../core/data/services/service_exporter.dart';
import '../../../../core/utils/util_exporter.dart';
import '../Servic/servic.dart';

class BankTransferController extends GetxController {
  BankTransferRepo bankTransferRepo;
  BankTransferController({required this.bankTransferRepo});

  bool isPageLoading = false;

  TextEditingController bankNameController = TextEditingController();
  TextEditingController bankAccountNameController = TextEditingController();
  TextEditingController bankAccountNumberController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController pinController = TextEditingController();

  String get getBankName => bankNameController.text;
  String get getAmount => amountController.text;

  List<String> otpType = [];
  String selectedOtpType = "";
  double userCurrentBalance = 0.0;
  GlobalChargeModel? globalChargeModel;

  List<BankDataModel> bankListDataList = [];
  List<BankDataModel> filterBankListDataList = [];
  BankDataModel? selectedBank;
  List<MyAddedBank> mySavedBankList = [];
  MyAddedBank? selectedMyAccount;
  List<UsersDynamicFormSubmittedDataModel>? selectedBankDynamicFormAutofillData;
  ModuleGlobalSubmitTransactionModel? moduleGlobalSubmitTransactionModel;
  String actionRemark = "bank_transfer";

  bool isVerifyingAccount = false;
  bool isSubmitLoading = false;
  bool isSubmitSaveBankLoading = false;
  bool isHistoryLoading = false;
  int currentIndex = 0;
  int page = 1;
  String? nextPageUrl;
  List<BankTransferDataModel> bankTransferHistoryList = [];
  String isDeleteSaveBankIDLoading = "-1";

  // Correct token getter using SharedPreferenceService
  String? get userToken {
    try {
      // Get token from SharedPreferenceService
      final token = SharedPreferenceService.getString(SharedPreferenceService.accessTokenKey);
      final tokenType = SharedPreferenceService.getString(SharedPreferenceService.accessTokenType);

      print("🔑 Token from SharedPreference:");
      print("  - Token: ${token != null && token.isNotEmpty ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'NULL'}");
      print("  - Token Type: $tokenType");
      print("  - Token exists: ${token != null && token.isNotEmpty}");

      if (token != null && token.isNotEmpty) {
        return token;
      }

      return null;
    } catch (e) {
      print("❌ Error getting token from SharedPreference: $e");
      return null;
    }
  }

  // Check if user is logged in
  bool get isUserLoggedIn {
    try {
      final isLoggedIn = SharedPreferenceService.getIsLoggedIn();
      final token = SharedPreferenceService.getString(SharedPreferenceService.accessTokenKey);

      print("🔐 Login Status Check:");
      print("  - Is Logged In: $isLoggedIn");
      print("  - Has Token: ${token != null && token.isNotEmpty}");
      print("  - Token: ${token != null ? '${token.substring(0, token.length > 20 ? 20 : token.length)}...' : 'NULL'}");

      return isLoggedIn && (token != null && token.isNotEmpty);
    } catch (e) {
      print("❌ Error checking login status: $e");
      return false;
    }
  }

  // UPDATED: Bank code getter that uses the actual bank_code from database
  String? get selectedBankCode {
    if (selectedBank == null) return null;

    // Use the bank_code from database, fallback to ID if null
    final bankCode = selectedBank?.bankCode;
    final bankId = selectedBank?.id?.toString();

    print("🔍 BANK CODE DEBUG:");
    print("  - Bank Name: ${selectedBank?.name}");
    print("  - Bank ID: $bankId");
    print("  - Bank Code from DB: $bankCode");

    final resolvedCode = bankCode ?? bankId;

    print("🎯 Using Bank Code: $resolvedCode");
    return resolvedCode;
  }

  // Debug SharedPreferenceService
  void debugSharedPreferences() {
    try {
      print("=== SHARED PREFERENCES DEBUG ===");
      print("Is Logged In: ${SharedPreferenceService.getIsLoggedIn()}");
      print("Access Token: ${SharedPreferenceService.getString(SharedPreferenceService.accessTokenKey) != null ? 'EXISTS' : 'NULL'}");
      print("Token Type: ${SharedPreferenceService.getString(SharedPreferenceService.accessTokenType)}");
      print("User Phone: ${SharedPreferenceService.getUserPhoneNumber()}");
      print("Remember Me: ${SharedPreferenceService.getRememberMe()}");
      print("=== END SHARED PREFERENCES DEBUG ===");
    } catch (e) {
      print("❌ SharedPreferences debug error: $e");
    }
  }

  // Debug method to check storage
  void debugStorage() {
    try {
      final box = GetStorage();
      final allKeys = box.getKeys();

      print("=== GET STORAGE DEBUG ===");
      print("Total keys in GetStorage: ${allKeys.length}");

      for (final key in allKeys) {
        final value = box.read(key);
        print("🔑 Key: '$key' = '$value' (Type: ${value.runtimeType})");
      }
      print("=== END GET STORAGE DEBUG ===");
    } catch (e) {
      print("❌ GetStorage debug error: $e");
    }
  }

  // UPDATED: Debug method to show all banks with their actual bank codes
  void debugAllBanks() {
    print("=== ALL BANKS WITH BANK CODES ===");
    for (var bank in bankListDataList) {
      print("🏦 ${bank.name}");
      print("  - ID: ${bank.id}");
      print("  - Bank Code: ${bank.bankCode}");

      // Show which code will be used for verification
      final codeToUse = bank.bankCode ?? bank.id?.toString();
      print("  - Will Use Code: $codeToUse");

      print("---");
    }
    print("=== END BANKS DEBUG ===");
  }

  // UPDATED: Method to find bank by name or code
  void findBank(String searchTerm) {
    print("🔍 SEARCHING FOR BANK: $searchTerm");

    final lowerSearch = searchTerm.toLowerCase();
    bool found = false;

    for (var bank in bankListDataList) {
      final bankName = bank.name?.toLowerCase() ?? '';
      final bankCode = bank.bankCode ?? '';
      final bankId = bank.id?.toString() ?? '';

      if (bankName.contains(lowerSearch) ||
          bankCode.contains(lowerSearch) ||
          bankId.contains(lowerSearch)) {
        print("🎯 FOUND BANK:");
        print("  - Name: ${bank.name}");
        print("  - ID: ${bank.id}");
        print("  - Bank Code: ${bank.bankCode}");
        print("  - Will Use Code: ${bank.bankCode ?? bank.id?.toString()}");
        found = true;
      }
    }

    if (!found) {
      print("❌ No bank found matching: $searchTerm");
    }
  }

  Future<void> initController({bool forceLoad = true}) async {
    isPageLoading = forceLoad;
    update();
    await loadBankTransferInfo();

    // Debug banks after loading
    debugAllBanks();

    isPageLoading = false;
    update();
  }

  Future<void> loadBankTransferInfo() async {
    try {
      ResponseModel responseModel = await bankTransferRepo.bankTransferInfoData();
      if (responseModel.statusCode == 200) {
        final bankTransferInfoResponseModel = bankTransferInfoResponseModelFromJson(
          jsonEncode(responseModel.responseJson),
        );
        if (bankTransferInfoResponseModel.status == "success") {
          final data = bankTransferInfoResponseModel.data;
          if (data != null) {
            otpType = data.otpType ?? [];
            globalChargeModel = data.bankTransferCharge;
            userCurrentBalance = data.getCurrentBalance();
            if (data.allBanks != null) {
              bankListDataList = data.allBanks ?? [];
              filterBankListDataList = bankListDataList;
            }
            if (data.mySavedBanks != null) {
              mySavedBankList = data.mySavedBanks ?? [];
            }
            update();
          }
        } else {
          CustomSnackBar.error(
            errorList: bankTransferInfoResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    }
  }

  void filterBankListName(String name) {
    selectedMyAccount = null;
    var filteredList = filterBankListDataList
        .where((ngo) => ngo.name?.toLowerCase().contains(name.toLowerCase()) ?? false)
        .toList();
    if (name.trim().isNotEmpty) {
      filterBankListDataList = filteredList;
    } else {
      filterBankListDataList = bankListDataList;
    }
    update();
  }

  void selectAnOtpType(String otpType) {
    selectedOtpType = otpType;
    update();
  }

  String getOtpType(String value) {
    return value == "email"
        ? MyStrings.email.tr
        : value == "sms"
        ? MyStrings.phone.tr
        : "";
  }

  List<MyAddedBank> getUniqueBankIdList() {
    final uniqueBankIds = <String>{};
    return mySavedBankList.where((item) => uniqueBankIds.add(item.bankId ?? "")).toList();
  }

  void selectBankAccount(MyAddedBank? value) {
    selectedMyAccount = null;
    update();
    selectedMyAccount = value;
    update();
  }

  void selectBankOnTap(BankDataModel value) {
    selectedBank = value;
    update();

    // Debug the selected bank's code
    print("🎯 Bank Selected: ${value.name}");
    print("🎯 Bank ID: ${value.id}");
    print("🎯 Bank Code from DB: ${value.bankCode}");
    print("🎯 Will Use Code: $selectedBankCode");
  }

  void selectedBankDynamicFormAutofillDataOnTap(
      List<UsersDynamicFormSubmittedDataModel>? value,
      ) {
    selectedBankDynamicFormAutofillData = null;
    update();
    selectedBankDynamicFormAutofillData = value;
    bankAccountNameController.text = selectedMyAccount?.accountHolder ?? "";
    bankAccountNumberController.text = selectedMyAccount?.accountNumber ?? "";
    update();
  }

  void onChangeAmountControllerText(String value) {
    amountController.text = value;
    changeInfoWidget();
    update();
  }

  void clearFormData({VoidCallback? moreCallback}) {
    selectedBank = null;
    selectedMyAccount = null;
    amountController.clear();
    bankAccountNameController.clear();
    bankAccountNumberController.clear();
    if (moreCallback != null) {
      moreCallback();
    }
    update();
  }

  void clearTextEditingControllers() {
    bankAccountNameController.clear();
    bankAccountNumberController.clear();
    amountController.clear();
    pinController.clear();
  }

  double mainAmount = 0;
  String totalCharge = "";
  String payableAmountText = "";

  void changeInfoWidget() {
    mainAmount = double.tryParse(amountController.text) ?? 0.0;
    update();
    double percent = 0;
    double percentCharge = 0;
    double fixedCharge = 0;
    double tempTotalCharge = 0;

    if (selectedBank?.percentCharge == null) {
      percent = double.tryParse(globalChargeModel?.percentCharge ?? "0") ?? 0;
    } else {
      percent = double.tryParse(selectedBank?.percentCharge ?? "0") ?? 0;
    }
    percentCharge = mainAmount * percent / 100;

    if (selectedBank?.fixedCharge == null) {
      fixedCharge = double.tryParse(globalChargeModel?.fixedCharge ?? "0") ?? 0;
    } else {
      fixedCharge = double.tryParse(selectedBank?.fixedCharge ?? "0") ?? 0;
    }
    tempTotalCharge = percentCharge + fixedCharge;

    double capAmount = double.tryParse(globalChargeModel?.cap ?? "0") ?? 0;

    if (capAmount != -1.0 && capAmount != 1 && tempTotalCharge > capAmount) {
      tempTotalCharge = capAmount;
    }

    totalCharge = AppConverter.formatNumber('$tempTotalCharge', precision: 2);
    double payable = tempTotalCharge + mainAmount;
    payableAmountText = payableAmountText.length > 5
        ? AppConverter.roundDoubleAndRemoveTrailingZero(payable.toString())
        : AppConverter.formatNumber(payable.toString());
    update();
  }

  Future<void> submitThisProcess({
    void Function(BankTransferSubmitResponseModel)? onSuccessCallback,
    void Function(BankTransferSubmitResponseModel)? onVerifyOtpCallback,
    required List<KycFormModel> dynamicFormList,
  }) async {
    try {
      isSubmitLoading = true;
      update();
      ResponseModel responseModel = await bankTransferRepo.bankTransferOneTimeRequest(
        bankId: selectedBank?.id.toString() ?? "",
        accountName: bankAccountNameController.text,
        accountNumber: bankAccountNumberController.text,
        amount: amountController.text,
        otpType: selectedOtpType,
        dynamicFormList: dynamicFormList,
      );
      if (responseModel.statusCode == 200) {
        BankTransferSubmitResponseModel bankTransferSubmitResponseModel =
        BankTransferSubmitResponseModel.fromJson(responseModel.responseJson);

        if (bankTransferSubmitResponseModel.status == "success") {
          if (bankTransferSubmitResponseModel.remark == "otp") {
            if (onVerifyOtpCallback != null) {
              onVerifyOtpCallback(bankTransferSubmitResponseModel);
            }
            update();
          } else {
            if (bankTransferSubmitResponseModel.remark == "pin") {
              if (onSuccessCallback != null) {
                onSuccessCallback(bankTransferSubmitResponseModel);
              }
            }
          }
        } else {
          CustomSnackBar.error(
            errorList: bankTransferSubmitResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
        update();
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    } finally {
      isSubmitLoading = false;
      update();
    }
  }

  Future<void> pinVerificationProcess({
    void Function(BankTransferSubmitResponseModel)? onSuccessCallback,
  }) async {
    try {
      isSubmitLoading = true;
      update();
      ResponseModel responseModel = await bankTransferRepo.pinVerificationRequest(pin: pinController.text);
      if (responseModel.statusCode == 200) {
        BankTransferSubmitResponseModel bankTransferSubmitResponseModel =
        BankTransferSubmitResponseModel.fromJson(responseModel.responseJson);

        if (bankTransferSubmitResponseModel.status == "success") {
          moduleGlobalSubmitTransactionModel = bankTransferSubmitResponseModel.data?.bankTransfer;
          if (moduleGlobalSubmitTransactionModel != null) {
            if (onSuccessCallback != null) {
              onSuccessCallback(bankTransferSubmitResponseModel);
            }
          }
        } else {
          CustomSnackBar.error(
            errorList: bankTransferSubmitResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
        update();
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    } finally {
      isSubmitLoading = false;
      update();
    }
  }

  Future<void> submitSaveBankAccountProcess({
    required List<KycFormModel> dynamicFormList,
    VoidCallback? onSuccessCallback,
  }) async {
    try {
      isSubmitSaveBankLoading = true;
      update();
      ResponseModel responseModel = await bankTransferRepo.saveBankAccountRequest(
        bankId: selectedBank?.id.toString() ?? "",
        accountName: bankAccountNameController.text,
        accountNumber: bankAccountNumberController.text,
        dynamicFormList: dynamicFormList,
      );
      if (responseModel.statusCode == 200) {
        BankTransferAddNewBankSubmitResponseModel bankTransferAddNewBankSubmitResponseModel =
        BankTransferAddNewBankSubmitResponseModel.fromJson(responseModel.responseJson);

        if (bankTransferAddNewBankSubmitResponseModel.status == "success") {
          if (onSuccessCallback != null) {
            onSuccessCallback();
          }
          CustomSnackBar.success(
            successList: bankTransferAddNewBankSubmitResponseModel.message ?? [MyStrings.requestSuccess],
          );
        } else {
          CustomSnackBar.error(
            errorList: bankTransferAddNewBankSubmitResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
        update();
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    } finally {
      isSubmitSaveBankLoading = false;
      update();
    }
  }

  Future<void> deleteBankAccount({String bankAccountID = ""}) async {
    try {
      isSubmitSaveBankLoading = true;
      isDeleteSaveBankIDLoading = bankAccountID;
      update();
      ResponseModel responseModel = await bankTransferRepo.deleteBankAccount(bankAccountID);
      if (responseModel.statusCode == 200) {
        BankTransferAddNewBankSubmitResponseModel bankTransferAddNewBankSubmitResponseModel =
        BankTransferAddNewBankSubmitResponseModel.fromJson(responseModel.responseJson);

        if (bankTransferAddNewBankSubmitResponseModel.status == "success") {
          CustomSnackBar.success(
            successList: bankTransferAddNewBankSubmitResponseModel.message ?? [MyStrings.requestSuccess],
          );
          initController(forceLoad: false);
        } else {
          CustomSnackBar.error(
            errorList: bankTransferAddNewBankSubmitResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
        update();
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    } finally {
      isDeleteSaveBankIDLoading = "-1";
      isSubmitSaveBankLoading = false;
      update();
    }
  }

  void initialHistoryData() async {
    isHistoryLoading = true;
    page = 0;
    nextPageUrl = null;
    bankTransferHistoryList.clear();
    await getBankTransferHistoryDataList();
  }

  Future<void> getBankTransferHistoryDataList({bool forceLoad = true}) async {
    try {
      page = page + 1;
      isHistoryLoading = forceLoad;
      update();
      ResponseModel responseModel = await bankTransferRepo.bankTransferHistory(page);
      if (responseModel.statusCode == 200) {
        BankTransferHistoryResponseModel bankTransferHistoryResponseModel =
        bankTransferHistoryResponseModelFromJson(jsonEncode(responseModel.responseJson));
        if (bankTransferHistoryResponseModel.status == "success") {
          nextPageUrl = bankTransferHistoryResponseModel.data?.history?.nextPageUrl;
          bankTransferHistoryList.addAll(bankTransferHistoryResponseModel.data?.history?.data ?? []);
        } else {
          CustomSnackBar.error(
            errorList: bankTransferHistoryResponseModel.message ?? [MyStrings.somethingWentWrong],
          );
        }
        update();
        isHistoryLoading = false;
        update();
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e.toString());
    }
    isHistoryLoading = false;
    update();
  }

  bool hasNext() {
    return nextPageUrl != null && nextPageUrl!.isNotEmpty && nextPageUrl != 'null';
  }

  // Helper method to safely convert messages to List<String>
  List<String> getMessageList(dynamic message) {
    if (message == null) return [];
    if (message is List) {
      return message.map((e) => e.toString()).toList();
    }
    return [message.toString()];
  }

  /* ----------  auto-verify account number ---------- */
  Future<void> verifyAccountNumber() async {
    final acc = bankAccountNumberController.text.trim();
    final bankCode = selectedBankCode;

    print("=== VERIFY ACCOUNT CALLED ===");
    print("🔍 VERIFICATION PARAMETERS:");
    print("  - Account: $acc, Length: ${acc.length}");
    print("  - Selected Bank: ${selectedBank?.name}");
    print("  - Selected Bank ID: ${selectedBank?.id}");
    print("  - Selected Bank Code: $bankCode");

    // Check if we have token
    final token = userToken;
    if (token == null) {
      print("❌ No authentication token found");
      CustomSnackBar.error(errorList: ["Authentication required. Please login again."]);
      return;
    }

    if (acc.length < 10 || bankCode == null) {
      print("❌ Verification skipped - Invalid parameters");
      return;
    }

    isVerifyingAccount = true;
    update();

    try {
      print("🔄 Calling verification API...");
      final endpoint = 'https://pay.edubest.com.ng/api/bank/verify-account';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'account_number': acc,
          'bank_code': bankCode,
        }),
      );

      print("📡 API REQUEST DETAILS:");
      print("  - Bank Code Sent: $bankCode");
      print("  - Response Status: ${response.statusCode}");
      print("  - Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print("✅ API Response - Status: ${body['status']}");

        if (body['status'] == 'success') {
          // ✅ SUCCESS CASE
          final accountName = body['account_name'] ?? '';
          print("🎯 Account Name Found: $accountName");
          bankAccountNameController.text = accountName;
          CustomSnackBar.success(successList: ["Account verified successfully"]);
        } else {
          // ❌ ERROR CASE
          print("❌ API returned error status");
          bankAccountNameController.clear();

          final errorMessages = getMessageList(body['message']);
          if (errorMessages.isNotEmpty) {
            CustomSnackBar.error(errorList: errorMessages);
          }
        }
      } else {
        print("❌ API Error - Status Code: ${response.statusCode}");
        bankAccountNameController.clear();
        CustomSnackBar.error(errorList: ["Server error: ${response.statusCode}"]);
      }
    } catch (e) {
      print("💥 Exception during verification: $e");
      bankAccountNameController.clear();
      CustomSnackBar.error(errorList: ["Network error: $e"]);
    }

    isVerifyingAccount = false;
    update();
    print("=== VERIFICATION COMPLETE ===");
  }
}