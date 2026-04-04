import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(
    uri,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
  );

  if (!launched) {
    throw StateError('Could not launch URL: $url');
  }
}
