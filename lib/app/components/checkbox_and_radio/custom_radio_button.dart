// import 'package:flutter/material.dart';
// import 'package:ovopay/app/components/text/header_text.dart';
//
// import '../../../core/utils/util_exporter.dart';
//
// class CustomRadioButton extends StatefulWidget {
//   final String? title;
//   final String? instruction;
//   final String? selectedValue;
//   final int selectedIndex;
//   final List<String> list;
//   final ValueChanged? onChanged;
//   final bool isRequired;
//
//   const CustomRadioButton({
//     super.key,
//     this.title,
//     this.instruction,
//     this.selectedIndex = 0,
//     this.selectedValue,
//     required this.list,
//     this.onChanged,
//     this.isRequired = false,
//   });
//
//   @override
//   State<CustomRadioButton> createState() => _CustomRadioButtonState();
// }
//
// class _CustomRadioButtonState extends State<CustomRadioButton> {
//   final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
//   @override
//   Widget build(BuildContext context) {
//     if (widget.list.isEmpty) {
//       return Container();
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             HeaderText(
//               text: (widget.title ?? "").toCapitalized(),
//               textStyle: MyTextStyle.sectionTitle3.copyWith(
//                 color: MyColor.getHeaderTextColor(),
//               ),
//             ),
//             if (widget.instruction != null) ...[
//               spaceSide(Dimensions.space5),
//               Tooltip(
//                 onTriggered: () {},
//                 key: _tooltipKey,
//                 message: "${widget.instruction}",
//                 child: InkWell(
//                   onTap: () {
//                     _tooltipKey.currentState?.ensureTooltipVisible();
//                   },
//                   child: Icon(
//                     Icons.info_outline_rounded,
//                     size: Dimensions.space18,
//                     color: MyColor.getBodyTextColor(),
//                   ),
//                 ),
//               ),
//             ],
//             if (widget.isRequired) ...[
//               spaceSide(Dimensions.space5),
//               Text(
//                 "*",
//                 style: MyTextStyle.sectionSubTitle1.copyWith(
//                   color: MyColor.error,
//                 ),
//               ),
//             ],
//           ],
//         ),
//         Column(
//           children: [
//             RadioGroup<int>(
//               groupValue: widget.selectedIndex,
//               onChanged: (int? newValue) {
//                 setState(() {
//                   if (newValue != null) {
//                     widget.onChanged!(newValue);
//                   }
//                 });
//               },
//               child: Column(
//                 children: List<RadioListTile<int>>.generate(widget.list.length, (
//                   int index,
//                 ) {
//                   return RadioListTile<int>(
//                     contentPadding: EdgeInsets.zero,
//                     value: index,
//                     radioSide: BorderSide(color: MyColor.getBorderColor(), width: 1.5),
//                     activeColor: MyColor.getPrimaryColor(),
//                     title: Text(
//                       widget.list[index],
//                       style: MyTextStyle.sectionSubTitle1.copyWith(
//                         color: MyColor.getBodyTextColor(),
//                       ),
//                     ),
//                     selected: index == widget.selectedIndex,
//                   );
//                 }),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:ovopay/app/components/text/header_text.dart';
import '../../../core/utils/util_exporter.dart';

class CustomRadioButton extends StatefulWidget {
  final String? title;
  final String? instruction;
  final String? selectedValue;
  final int selectedIndex;
  final List<String> list;
  final ValueChanged? onChanged;
  final bool isRequired;

  const CustomRadioButton({
    super.key,
    this.title,
    this.instruction,
    this.selectedIndex = 0,
    this.selectedValue,
    required this.list,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  State<CustomRadioButton> createState() => _CustomRadioButtonState();
}

class _CustomRadioButtonState extends State<CustomRadioButton> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    if (widget.list.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HeaderText(
              text: (widget.title ?? "").toCapitalized(),
              textStyle: MyTextStyle.sectionTitle3.copyWith(
                color: MyColor.getHeaderTextColor(),
              ),
            ),
            if (widget.instruction != null) ...[
              const SizedBox(width: 5), // Replaced spaceSide(Dimensions.space5)
              Tooltip(
                onTriggered: () {},
                key: _tooltipKey,
                message: "${widget.instruction}",
                child: InkWell(
                  onTap: () {
                    _tooltipKey.currentState?.ensureTooltipVisible();
                  },
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18, // Replaced Dimensions.space18
                    color: MyColor.getBodyTextColor(),
                  ),
                ),
              ),
            ],
            if (widget.isRequired) ...[
              const SizedBox(width: 5), // Replaced spaceSide(Dimensions.space5)
              Text(
                "*",
                style: MyTextStyle.sectionSubTitle1.copyWith(
                  color: MyColor.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10), // Replaced spaceVertical(Dimensions.space10)
        Column(
          children: List<Widget>.generate(widget.list.length, (int index) {
            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: MyColor.getBorderColor(),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RadioListTile<int>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    value: index,
                    groupValue: widget.selectedIndex,
                    onChanged: (int? newValue) {
                      setState(() {
                        if (newValue != null) {
                          widget.onChanged!(newValue);
                        }
                      });
                    },
                    activeColor: MyColor.getPrimaryColor(),
                    title: Text(
                      widget.list[index],
                      style: MyTextStyle.sectionSubTitle1.copyWith(
                        color: MyColor.getBodyTextColor(),
                      ),
                    ),
                    selected: index == widget.selectedIndex,
                  ),
                ),
                if (index < widget.list.length - 1)
                  const SizedBox(height: 8), // Replaced spaceVertical(Dimensions.space8)
              ],
            );
          }),
        ),
      ],
    );
  }
}