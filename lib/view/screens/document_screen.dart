import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:nestline_circuit/view/widgets/shell.dart';

/// Opens a hosted HTML document in an embedded WebView.
class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key, required this.title, required this.url});

  static const String privacyUrl =
      'https://nestlinnespeedway.com/privacy-policy.html';
  static const String supportUrl = 'https://nestlinnespeedway.com/support.html';

  final String title;
  final String url;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  late final WebViewController _controller;

  static const String _lightPage = r'''
(function () {
  var css = ':root{color-scheme:light only;}html,body{background:#ffffff !important;color:#111111 !important;}';
  var s = document.createElement('style');
  s.setAttribute('data-nestline-light', '1');
  s.appendChild(document.createTextNode(css));
  (document.head || document.documentElement).appendChild(s);
})();
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            _controller.runJavaScript(_lightPage);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stage(
      title: widget.title,
      onBack: () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
