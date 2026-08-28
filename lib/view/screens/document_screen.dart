import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:nestline_circuit/app/pigment.dart';
import 'package:nestline_circuit/view/widgets/shell.dart';

/// Renders a bundled HTML document. Used for the privacy policy so the text
/// ships with the app and needs no network access.
class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key, required this.title, required this.asset});

  final String title;
  final String asset;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..setBackgroundColor(Pigment.pitch)
    ..loadFlutterAsset(widget.asset);

  @override
  Widget build(BuildContext context) {
    return Stage(
      title: widget.title,
      onBack: () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
