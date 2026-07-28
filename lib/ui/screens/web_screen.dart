import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/palette.dart';
import '../widgets/ui_kit.dart';

/// Renders a bundled HTML document. Used for the privacy policy so the text
/// ships with the app and needs no network access.
class WebScreen extends StatefulWidget {
  const WebScreen({super.key, required this.title, required this.asset});

  final String title;
  final String asset;

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..setBackgroundColor(Palette.pitch)
    ..loadFlutterAsset(widget.asset);

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      title: widget.title,
      onBack: () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
