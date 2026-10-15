import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:letscheck/cmk_colors.dart';

class HostCardWidget extends StatelessWidget {
  final String alias;
  final cmk_api.Host host;

  const HostCardWidget({super.key, required this.alias, required this.host});

  @override
  Widget build(BuildContext context) {
    Widget icon = Icon(Icons.check, color: CmkColors.ok);
    switch (host.state) {
      case cmk_api.hostStateUp:
        icon = Icon(Icons.check, color: CmkColors.ok);
        break;
      case cmk_api.hostStateUnreachable:
        icon =
            FaIcon(FontAwesomeIcons.triangleExclamation, color: CmkColors.warn);
        break;
      case cmk_api.hostStateDown:
        icon = FaIcon(FontAwesomeIcons.ban, color: CmkColors.crit);
        break;
      case cmk_api.hostStatePending:
        icon = FaIcon(FontAwesomeIcons.circleQuestion, color: CmkColors.unknown);
        break;
    }

    return Card(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: icon,
          ),
          Expanded(
            flex: 20,
            child: SelectableText(
              host.hostName!,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            flex: 2,
            child: IconButton(
              onPressed: () {
                context.push(
                    '/conn/$alias/host/${Uri.encodeComponent(host.hostName!)}');
              },
              tooltip: "Goto host",
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
