import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/locale_provider.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.info});

  final UpdateInfo info;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    return AlertDialog(
      title: Text(s.updateAvailable),
      content: Text(s.updateAvailableDesc(info.version)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.later),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            final uri = Uri.parse(info.releaseUrl);
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          child: Text(s.downloadUpdate),
        ),
      ],
    );
  }
}
