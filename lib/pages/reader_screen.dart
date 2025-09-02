import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReaderScreen extends StatefulWidget {
  final Uri url;
  const ReaderScreen({super.key, required this.url});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final WebViewController _wc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
        setState(() => _loading = false);
      }))
      ..loadRequest(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.url.host),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _wc.reload()),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _wc),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}