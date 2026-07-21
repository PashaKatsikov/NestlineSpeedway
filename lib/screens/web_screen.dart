import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_colors.dart';
import '../widgets/common.dart';

enum WebPage { privacy, support }

extension on WebPage {
  String get title =>
      this == WebPage.privacy ? 'Privacy Policy' : 'Support';
  IconData get icon => this == WebPage.privacy
      ? Icons.privacy_tip_rounded
      : Icons.support_agent_rounded;
  String get url => this == WebPage.privacy
      ? 'https://nestlinnespeedway.com/privacy-policy.html'
      : 'https://nestlinnespeedway.com/support.html';
  String get asset => this == WebPage.privacy
      ? 'assets/web/privacy.html'
      : 'assets/web/support.html';
}

/// Shows the Privacy Policy / Support pages. Loads the live URL when online and
/// automatically falls back to a bundled offline copy so the pages are always
/// available, even with no internet connection.
class WebScreen extends StatefulWidget {
  final WebPage page;
  const WebScreen({super.key, required this.page});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _usedFallback = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Offline / host unreachable -> show the bundled copy.
            if (!_usedFallback &&
                (error.isForMainFrame ?? true)) {
              _usedFallback = true;
              _controller.loadFlutterAsset(widget.page.asset);
            }
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    try {
      await _controller.loadRequest(Uri.parse(widget.page.url));
    } catch (_) {
      _usedFallback = true;
      await _controller.loadFlutterAsset(widget.page.asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ScreenBackground(
        gradient: const LinearGradient(colors: [Colors.white, Colors.white]),
        child: Column(
          children: [
            ScreenHeader(
              title: widget.page.title,
              icon: widget.page.icon,
              actions: [
                RoundIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    _usedFallback = false;
                    _load();
                  },
                ),
              ],
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.woodDark.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.gold),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
