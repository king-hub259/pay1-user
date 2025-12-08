import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ovopay/app/components/buttons/app_main_submit_button.dart';
import 'package:ovopay/app/components/card/custom_card.dart';
import 'package:ovopay/app/components/card/my_custom_scaffold.dart';
import 'package:ovopay/app/components/text-field/rounded_text_field.dart';
import 'package:ovopay/app/components/text/header_text_smaller.dart';
import 'package:ovopay/app/screens/bank_transfer_screen/controller/bank_transfer_controller.dart';
import 'package:ovopay/app/screens/global/controller/global_dynamic_form_controller.dart';
import '../../../../../core/utils/util_exporter.dart';

class BankTransferAddNewBankAccountScreen extends StatefulWidget {
  const BankTransferAddNewBankAccountScreen({super.key});

  @override
  State<BankTransferAddNewBankAccountScreen> createState() => _BankTransferAddNewBankAccountScreenState();
}

class _BankTransferAddNewBankAccountScreenState extends State<BankTransferAddNewBankAccountScreen> {
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MyCustomScaffold(
      pageTitle: MyStrings.addBankAccount,
      body: GetBuilder<BankTransferController>(
        builder: (controller) {
          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                controller.clearFormData(
                  moreCallback: () {
                    try {
                      Get.find<GlobalDynamicFormController>().formList.clear();
                      Get.find<GlobalDynamicFormController>().update();
                    } catch (e) {
                      printE(e);
                    }
                  },
                );
              }
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CustomAppCard(
                    width: double.infinity,
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeaderTextSmaller(
                            textAlign: TextAlign.center,
                            text: "${MyStrings.accountInformation.tr} ",
                          ),
                          spaceDown(Dimensions.space24),

                          // ACCOUNT NUMBER FIRST
                          RoundedTextField(
                            isRequired: true,
                            controller: controller.bankAccountNumberController,
                            showLabelText: true,
                            labelText: MyStrings.accountNumber,
                            hintText: "",
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.number,
                            textInputFormatter: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value.toString().isEmpty) {
                                return MyStrings.kAccountNumberNullError.tr;
                              } else if (value.toString().length < 10) {
                                return "Account number must be 10 digits";
                              } else {
                                return null;
                              }
                            },
                            onChanged: (value) {
                              print("🔤 Account number changed: $value");
                              // Auto-verify when account number is complete
                              if (value.length == 10) {
                                print("✅ 10 digits reached, calling verification...");
                                controller.verifyAccountNumber();
                              } else {
                                // Clear account name if user deletes digits
                                controller.bankAccountNameController.clear();
                                controller.update();
                              }
                            },
                          ),
                          spaceDown(Dimensions.space16),

                          // ACCOUNT NAME - AUTO-FETCHED
                          RoundedTextField(
                            isRequired: true,
                            controller: controller.bankAccountNameController,
                            showLabelText: true,
                            labelText: MyStrings.accountName,
                            hintText: controller.isVerifyingAccount ? "Verifying..." : "Will auto-fill from bank",
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value.toString().isEmpty) {
                                return MyStrings.kAccountNameNullError.tr;
                              } else {
                                return null;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  spaceDown(Dimensions.space15),
                  AppMainSubmitButton(
                    isLoading: controller.isSubmitSaveBankLoading,
                    text: MyStrings.save,
                    onTap: () {
                      if (formKey.currentState?.validate() ?? false) {
                        controller.submitSaveBankAccountProcess(
                          dynamicFormList: [],
                          onSuccessCallback: () {
                            Get.back(result: "success");
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}