import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class OrbitWebViewPage extends StatefulWidget {
  const OrbitWebViewPage({Key? key}) : super(key: key);

  @override
  State<OrbitWebViewPage> createState() => _OrbitWebViewPageState();
}

class _OrbitWebViewPageState extends State<OrbitWebViewPage> {
  InAppWebViewController? webViewController;

  Future<String> _prepareLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/spacekit_page.html';
    final file = File(filePath);

    if (!await file.exists()) {
      final content = await rootBundle.loadString('lib/assets/spacekit_page.html');
      await file.writeAsString(content);
    }

    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orbit Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            onPressed: () {
              webViewController?.evaluateJavascript(
                source: "loadOrbitFromFlutter('Mars');",
              );
            },
          )
        ],
      ),
      body: FutureBuilder<String>(
        future: _prepareLocalFile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final path = snapshot.data!;
          return InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(File(path).uri.toString()),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onConsoleMessage: (controller, message) {
              print("🪐 JS console: ${message.message}");
            },
          );
        },
      ),
    );
  }
}
