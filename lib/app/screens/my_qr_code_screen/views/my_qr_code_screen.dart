import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovopay/app/components/buttons/custom_elevated_button.dart';
import 'package:ovopay/app/components/card/custom_card.dart';
import 'package:ovopay/app/components/card/my_custom_scaffold.dart';
import 'package:ovopay/app/components/image/my_asset_widget.dart';
import 'package:ovopay/app/components/image/my_network_image_widget.dart';
import 'package:ovopay/app/components/text/header_text.dart';
import 'package:ovopay/app/screens/my_qr_code_screen/controller/my_qr_code_controller.dart';
import 'package:ovopay/core/data/services/service_exporter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/utils/util_exporter.dart';

class MyQrCodeScreen extends StatefulWidget {
  const MyQrCodeScreen({super.key});

  @override
  State<MyQrCodeScreen> createState() => _MyQrCodeScreenState();
}

class _MyQrCodeScreenState extends State<MyQrCodeScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.put(MyQrCodeController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getMyQrCodeData();   // QR image
      controller.getVirtualAccount(); // virtual account data
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyCustomScaffold(
      pageTitle: MyStrings.qrCode,
      body: GetBuilder<MyQrCodeController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.space16.w),
            child: CustomAppCard(
              child: Skeletonizer(
                enabled: controller.isLoading,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /* ----------  USER NAME & PHONE  ---------- */
                    HeaderText(
                      text: SharedPreferenceService.getUserFullName(),
                      textAlign: TextAlign.center,
                      textStyle: MyTextStyle.headerH1.copyWith(
                        color: MyColor.getHeaderTextColor(),
                      ),
                    ),
                    SizedBox(height: Dimensions.space8.h),
                    HeaderText(
                      text: SharedPreferenceService.getUserPhoneNumber(),
                      textAlign: TextAlign.center,
                      textStyle: MyTextStyle.headerH3.copyWith(
                        fontWeight: FontWeight.w400,
                        color: MyColor.getBodyTextColor(),
                      ),
                    ),

                    /* ----------  VIRTUAL ACCOUNT (VISIBLE ALWAYS)  ---------- */
                    SizedBox(height: Dimensions.space20.h),
                    _DetailRow(label: 'Account', value: controller.virtualAccount),
                    SizedBox(height: Dimensions.space8.h),
                    _DetailRow(label: 'Bank',     value: controller.virtualBank),
                    SizedBox(height: Dimensions.space8.h),
                    _DetailRow(label: 'Name',     value: controller.virtualAcctName.isNotEmpty
                        ? controller.virtualAcctName
                        : SharedPreferenceService.getUserFullName()),

                    SizedBox(height: Dimensions.space30.h),

                    /* ----------  QR CODE  ---------- */
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        MyAssetImageWidget(
                          isSvg: true,
                          assetPath: MyIcons.qrCodeBgImage,
                          color: MyColor.getPrimaryColor(),
                          width: (context.width / 1.8).w,
                          height: (context.width / 1.8).w,
                          boxFit: BoxFit.contain,
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(Dimensions.space30),
                            child: FittedBox(
                              child: controller.qrCodeLink.isEmpty
                                  ? Container(
                                width: 220.w,
                                height: 220.h,
                                color: MyColor.black,
                              )
                                  : MyNetworkImageWidget(
                                imageUrl: controller.qrCodeLink,
                                width: 220.w,
                                height: 220.h,
                                boxFit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Dimensions.space24.h),
                    HeaderText(
                      text: MyStrings.shareQrCode.tr,
                      textAlign: TextAlign.center,
                      textStyle: MyTextStyle.headerH3.copyWith(
                        fontWeight: FontWeight.w400,
                        color: MyColor.getBodyTextColor(),
                      ),
                    ),
                    SizedBox(height: Dimensions.space30.h),

                    /* ----------  DOWNLOAD BUTTON  ---------- */
                    CustomElevatedBtn(
                      radius: Dimensions.largeRadius.r,
                      isLoading: controller.isDownloadLoading,
                      icon: Padding(
                        padding: EdgeInsets.all(Dimensions.space10.w),
                        child: MyAssetImageWidget(
                          color: MyColor.getPrimaryColor(),
                          assetPath: MyIcons.downloadNewIcon,
                          width: Dimensions.space24.w,
                          height: Dimensions.space24.w,
                          isSvg: true,
                        ),
                      ),
                      bgColor: MyColor.getPrimaryColor(),
                      text: MyStrings.downloadQRCode.tr,
                      onTap: () => controller.downloadAttachment(
                        controller.qrCodeLink,
                        "jpeg",
                      ),
                    ),
                    SizedBox(height: Dimensions.space20.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /* ----------------------------------------------------------
   *  Helper widget so we do not repeat the same Text style
   * --------------------------------------------------------*/
  Widget _DetailRow({required String label, required String value}) {
    return HeaderText(
      text: '$label :  ${value.isNotEmpty ? value : '—'}',
      textAlign: TextAlign.center,
      textStyle: MyTextStyle.headerH3.copyWith(
        fontWeight: FontWeight.w500,
        color: MyColor.getHeaderTextColor(),
      ),
    );
  }
}