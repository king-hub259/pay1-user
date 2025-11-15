// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:crop_image/crop_image.dart';
// import 'package:ovopay/core/utils/util_exporter.dart';
//
// class CustomImageCropper {
//   static Future<void> showCropDialog({
//     required BuildContext context,
//     required Uint8List imageBytes,
//     required Function(File) onCropped,
//   }) async {
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => _CropperDialog(
//         imageBytes: imageBytes,
//         onCropped: onCropped,
//       ),
//     );
//   }
// }
//
// class _CropperDialog extends StatefulWidget {
//   final Uint8List imageBytes;
//   final Function(File) onCropped;
//
//   const _CropperDialog({
//     required this.imageBytes,
//     required this.onCropped,
//   });
//
//   @override
//   State<_CropperDialog> createState() => _CropperDialogState();
// }
//
// class _CropperDialogState extends State<_CropperDialog> {
//   final CropController _cropController = CropController();
//   bool _isCropping = false;
//
//   // Crop shape options
//   CropAspectRatio _currentCropShape = CropAspectRatio.preset_1x1;
//
//   final Map<CropAspectRatio, IconData> shapeIcons = {
//     CropAspectRatio.preset_1x1: Icons.crop_square,
//     CropAspectRatio.preset_3x2: Icons.crop_3_2,
//     CropAspectRatio.preset_4x3: Icons.crop_4_3,
//     CropAspectRatio.preset_16x9: Icons.crop_16_9,
//     CropAspectRatio.ratio_1x1: Icons.crop_square,
//     CropAspectRatio.ratio_3x2: Icons.crop_3_2,
//     CropAspectRatio.ratio_4x3: Icons.crop_4_3,
//     CropAspectRatio.ratio_16x9: Icons.crop_16_9,
//   };
//
//   Future<void> _cropImage() async {
//     setState(() => _isCropping = true);
//
//     try {
//       final croppedBytes = await _cropController.crop();
//       if (croppedBytes == null) throw Exception('Failed to crop image');
//
//       final tempDir = Directory.systemTemp;
//       final file = File(
//         '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
//       );
//       await file.writeAsBytes(croppedBytes);
//
//       if (!mounted) return;
//       Navigator.of(context).pop();
//       widget.onCropped(file);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error cropping image: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _isCropping = false);
//     }
//   }
//
//   void _rotateImage() {
//     _cropController.rotateRight();
//   }
//
//   void _changeCropShape() {
//     final shapes = [
//       CropAspectRatio.preset_1x1,
//       CropAspectRatio.preset_3x2,
//       CropAspectRatio.preset_4x3,
//       CropAspectRatio.preset_16x9,
//     ];
//
//     final currentIndex = shapes.indexOf(_currentCropShape);
//     final nextIndex = (currentIndex + 1) % shapes.length;
//
//     setState(() {
//       _currentCropShape = shapes[nextIndex];
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isTablet = screenSize.width >= 600;
//
//     final dialogWidth = isTablet ? 500.0 : double.infinity;
//     final dialogHeight = isTablet ? 600.0 : 500.0;
//
//     return Dialog(
//       backgroundColor: MyColor.getWhiteColor(),
//       insetPadding: const EdgeInsets.all(20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: dialogWidth,
//         height: dialogHeight,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // 🔹 Header
//             Container(
//               decoration: BoxDecoration(
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//                 color: MyColor.getPrimaryColor(),
//               ),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.close, color: MyColor.getWhiteColor()),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                   Expanded(
//                     child: Text(
//                       MyStrings.cropImage.tr,
//                       textAlign: TextAlign.center,
//                       style: MyTextStyle.sectionTitle.copyWith(color: MyColor.getWhiteColor()),
//                     ),
//                   ),
//                   IconButton(
//                     icon: _isCropping
//                         ? SizedBox(
//                       height: 22,
//                       width: 22,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: MyColor.getWhiteColor(),
//                       ),
//                     )
//                         : Icon(Icons.done, color: MyColor.getWhiteColor()),
//                     onPressed: _isCropping ? null : _cropImage,
//                   ),
//                 ],
//               ),
//             ),
//
//             // 🔹 Image crop area
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: CropImage(
//                   controller: _cropController,
//                   image: Image.memory(widget.imageBytes),
//                   aspectRatio: _currentCropShape,
//                   paddingSize: 0.0,
//                   alwaysMove: true,
//                   // Custom paint for circular crop (if needed)
//                   customCornerPaint: (canvas, size, edge, paint) {
//                     if (_currentCropShape == CropAspectRatio.preset_1x1) {
//                       // You can customize the corner paint here
//                       final cornerPath = Path();
//                       cornerPath.moveTo(0, 0);
//                       cornerPath.lineTo(size.width, 0);
//                       cornerPath.lineTo(0, size.height);
//                       cornerPath.close();
//                       canvas.drawPath(cornerPath, paint);
//                     }
//                   },
//                 ),
//               ),
//             ),
//
//             // 🔹 Bottom Controls
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _bottomButton(
//                     icon: Icons.rotate_90_degrees_ccw,
//                     onTap: _rotateImage,
//                   ),
//                   _bottomButton(
//                     icon: shapeIcons[_currentCropShape] ?? Icons.crop_square,
//                     onTap: _changeCropShape,
//                   ),
//                   _bottomButton(
//                     icon: Icons.flip,
//                     onTap: () => _cropController.flip(),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _bottomButton({
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: MyColor.primaryColor.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Icon(icon, color: MyColor.primaryColor, size: 24),
//       ),
//     );
//   }
// }