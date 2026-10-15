import 'dart:async';

import 'package:checkmk_api/checkmk_api.dart' as cmk_api;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:letscheck/cmk_colors.dart';
import 'package:letscheck/providers/providers.dart';

/// Host and service alerts of the last hours, like the Checkmk
/// "Events of recent 4 hours" dashlet.
class RecentEventsWidget extends ConsumerStatefulWidget {
  final String alias;
  final Duration window;

  const RecentEventsWidget(
      {super.key, required this.alias, this.window = const Duration(hours: 4)});

  @override
  ConsumerState<RecentEventsWidget> createState() => _RecentEventsState();
}

class _RecentEventsState extends ConsumerState<RecentEventsWidget> {
  List<cmk_api.Log>? _events;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final client = await ref.read(clientProvider(widget.alias).future);
      final events = await client.getViewEvents(
          fromSecs: widget.window.inSeconds, includeOk: true);
      if (!mounted) return;
      setState(() {
        _events = events;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  static Color _color(int state) => switch (state) {
        cmk_api.svcStateOk => CmkColors.ok,
        cmk_api.svcStateWarn => CmkColors.warn,
        cmk_api.svcStateCritical => CmkColors.crit,
        _ => CmkColors.unknown,
      };

  static String _label(int state) => switch (state) {
        cmk_api.svcStateOk => 'OK',
        cmk_api.svcStateWarn => 'WARN',
        cmk_api.svcStateCritical => 'CRIT',
        _ => 'UNKN',
      };

  static String _age(DateTime t) {
    final d = DateTime.now().toUtc().difference(t);
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    if (d.inHours < 1) return '${d.inMinutes} min';
    return '${d.inHours} h ${d.inMinutes % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    Widget body;
    if (events == null && _error == null) {
      body = const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()));
    } else if (events == null) {
      body = Padding(
          padding: const EdgeInsets.all(12),
          child: Text('$_error', style: TextStyle(color: CmkColors.crit)));
    } else if (events.isEmpty) {
      body = Padding(
          padding: const EdgeInsets.all(12),
          child: Text('No events',
              style: TextStyle(color: CmkColors.textMuted)));
    } else {
      body = ListView.builder(
        shrinkWrap: true,
        itemCount: events.length,
        itemBuilder: (context, i) {
          final e = events[i];
          final isService = e.displayName.isNotEmpty;
          return InkWell(
            onTap: () => context.push(isService
                ? '/conn/${widget.alias}/host/${Uri.encodeComponent(e.hostName)}/services/${Uri.encodeComponent(e.displayName)}'
                : '/conn/${widget.alias}/host/${Uri.encodeComponent(e.hostName)}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                        color: _color(e.state),
                        borderRadius: BorderRadius.circular(3)),
                    child: Center(
                        child: Text(_label(e.state),
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 62,
                    child: Text(_age(e.time),
                        style: TextStyle(
                            color: CmkColors.textMuted, fontSize: 12)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isService
                                ? '${e.hostName} › ${e.displayName}'
                                : e.hostName,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: CmkColors.text, fontSize: 13)),
                        Text(e.pluginOutput,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: CmkColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
                'Events of recent ${widget.window.inHours} hours'
                '${events != null ? ' (${events.length})' : ''}',
                style: TextStyle(
                    color: CmkColors.text, fontWeight: FontWeight.w600)),
          ),
          Flexible(child: body),
        ],
      ),
    );
  }
}
