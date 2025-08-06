import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class OrbitsWebViewPage extends StatelessWidget {
  const OrbitsWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text("NASA Orbits Viewer"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
        //  url: WebUri("https://liz581.github.io/bttc-orbits/"),
          url: WebUri("https://ssd.jpl.nasa.gov/tools/orbit_viewer.html"),
      //    url: WebUri("https://nasapsg.github.io/orbits/"),
        ),
      ),
    );
  }
}
