import 'package:flutter/material.dart';
import 'package:letscheck/cmk_colors.dart';

class SiteStatsNumberWidget extends StatelessWidget {
  final String caption;
  final int num;
  final Color zeroColor;
  final Color valueColor;
  final GestureTapCallback onTap;

  SiteStatsNumberWidget(
      {required this.caption,
      required this.num,
      required this.valueColor,
      required this.onTap,
      this.zeroColor = CmkColors.surfaceHigh});

  @override
  Widget build(BuildContext context) {
    final active = num > 0;
    // The "all" counter uses the accent colour as text, not as a fill.
    final isTotal = valueColor == CmkColors.accent;
    final fill = active && !isTotal ? valueColor : zeroColor;
    final textColor = isTotal
        ? CmkColors.text
        : (active ? Colors.black : CmkColors.textMuted);

    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: [
            Text(caption,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: CmkColors.textMuted)),
            SizedBox(height: 3),
            Container(
                width: 60,
                height: 26,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: CmkColors.border),
                ),
                child: Center(
                    child: Text(num.toString(),
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)))),
          ],
        ));
  }
}
