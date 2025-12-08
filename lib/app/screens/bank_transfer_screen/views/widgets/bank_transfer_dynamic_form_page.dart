import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ovopay/app/components/buttons/app_main_submit_button.dart';
import 'package:ovopay/app/components/card/custom_card.dart';
import 'package:ovopay/app/components/card/custom_contact_list_tile_card.dart';
import 'package:ovopay/app/components/image/my_network_image_widget.dart';
import 'package:ovopay/app/components/text-field/rounded_text_field.dart';
import 'package:ovopay/app/components/text/header_text_smaller.dart';
import 'package:ovopay/app/screens/bank_transfer_screen/controller/bank_transfer_controller.dart';
import 'package:ovopay/app/screens/global/controller/global_dynamic_form_controller.dart';
import 'package:ovopay/app/screens/global/views/dynamic_form_widget_view.dart';
import '../../../../../core/utils/util_exporter.dart';

class BankTransferDynamicFormPage extends StatefulWidget {
  const BankTransferDynamicFormPage({
    super.key,
    required this.context,
    required this.onSuccessCallback,
  });
  final VoidCallback onSuccessCallback;
  final BuildContext context;

  @override
  State<BankTransferDynamicFormPage> createState() => _BankTransferDynamicFormPageState();
}

class _BankTransferDynamicFormPageState extends State<BankTransferDynamicFormPage> {
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BankTransferController>(
      builder: (controller) {
        return SingleChildScrollView(
          child: Column(
            children: [
              if (controller.selectedBank != null) ...[
                CustomAppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomContactListTileCard(
                        padding: EdgeInsets.symmetric(vertical: Dimensions.space10),
                        leading: CustomAppCard(
                          width: Dimensions.space45.w,
                          height: Dimensions.space45.w,
                          radius: Dimensions.largeRadius.r,
                          padding: EdgeInsetsDirectional.all(Dimensions.space4.w),
                          child: MyNetworkImageWidget(
                            boxFit: BoxFit.scaleDown,
                            imageUrl: controller.selectedBank?.getBankImageUrl() ?? "",
                            isProfile: false,
                            radius: Dimensions.largeRadius.r,
                            width: Dimensions.space40.w,
                            height: Dimensions.space40.h,
                          ),
                        ),
                        subtitleStyle: MyTextStyle.sectionSubTitle1.copyWith(
                          color: MyColor.getBodyTextColor(),
                        ),
                        imagePath: "",
                        title: controller.selectedBank?.name ?? "",
                        subtitle: "",
                        showBorder: false,
                      ),
                    ],
                  ),
                ),
              ],
              spaceDown(Dimensions.space16),
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

                      // ACCOUNT NUMBER COMES FIRST
                      RoundedTextField(
                        forceFillColor: false,
                        readOnly: false,
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
                          // Auto-verify account number when user types
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

                      // ACCOUNT NAME - AUTO-FETCHED FROM BACKEND
                      RoundedTextField(
                        forceFillColor: false,
                        readOnly: true,
                        isRequired: true,
                        controller: controller.bankAccountNameController,
                        showLabelText: true,
                        labelText: MyStrings.accountName,
                        hintText: controller.isVerifyingAccount ? "Verifying account..." : "Will auto-fill from bank",
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value.toString().isEmpty) {
                            return "Please verify account number first";
                          } else {
                            return null;
                          }
                        },
                      ),
                      spaceDown(Dimensions.space20),

                      if (controller.selectedBank != null) ...[
                        DynamicFormWidgetView(
                          formList: controller.selectedBank?.form?.formData?.list ?? [],
                          autoFillDataList: controller.selectedBankDynamicFormAutofillData,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              spaceDown(Dimensions.space15),
              AppMainSubmitButton(
                text: MyStrings.continueText,
                onTap: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Get.find<GlobalDynamicFormController>().submitFormDataData(
                      widget.onSuccessCallback,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}