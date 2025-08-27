/*
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart' show rootBundle;

// Minimal row we care about.
// NOTE: MPCORB.DAT does NOT include MOID; we'll leave moid null in CSV.
class _MpcRow {
  final String des;      // packed / numeric designation (cols 0–7)
  final double? H;       // (cols 8–13)
  final double? a;       // semi-major axis AU (cols 92–103)
  final double? e;       // eccentricity (cols 70–79)  <-- see note
  final double? i;       // inclination deg (cols 60–68)

  _MpcRow(this.des, this.H, this.a, this.e, this.i);

  String toCsv() {
    // readable_des is left equal to des; you can try to decode “packed” designation if needed
    return '"$des","$des",${H ?? ""},${a ?? ""},${e ?? ""},${i ?? ""},""';
  }
}

class MpcDatToCsv {
  /// Convert MPCORB.DAT asset to a CSV string and return it.
  /// We do this in an isolate to avoid janking the UI.
  static Future<String> convertAssetToCsv({
    String assetPath = 'assets/MPCORB.DAT',
    int? maxRows, // for testing/dev you can cap how many lines to parse
  }) async {
    final raw = await rootBundle.loadString(assetPath);

    // Offload heavy parse to an isolate
    final p = ReceivePort();
    await Isolate.spawn<_IsolateArg>(
      _isoEntry,
      _IsolateArg(p.sendPort, raw, maxRows),
    );
    return await p.first as String;
  }

  // Isolate entry
  static void _isoEntry(_IsolateArg arg) {
    final lines = const LineSplitter().convert(arg.text);
    final buf = StringBuffer()
      ..writeln('readable_des,des,H,a,e,i,moid');

    var count = 0;
    for (final line in lines) {
      if (arg.maxRows != null && count >= arg.maxRows!) break;
      if (line.isEmpty || line.startsWith('#')) continue; // header/comment

      final row = _parseLineSafe(line);
      if (row != null) {
        buf.writeln(row.toCsv());
        count++;
      }
    }
    arg.sendPort.send(buf.toString());
  }

  // Fixed-width parsing. Column positions follow MPCORB.DAT (classic format).
  // IMPORTANT: MPC occasionally changes widths; if you see garbage values, re-check the spec.
  static _MpcRow? _parseLineSafe(String line) {
    String s(int start, int end) {
      // start inclusive, end exclusive; clamp to bounds
      final a = start.clamp(0, line.length);
      final b = end.clamp(0, line.length);
      if (a >= b) return '';
      return line.substring(a, b);
    }

    double? d(String v) => double.tryParse(v.trim());

    // Columns (0-indexed, end-exclusive). Conservative ranges:
    final des = s(0, 7).trim();         // designation/number
    if (des.isEmpty) return null;

    final H  = d(s(8, 13));             // absolute mag (H)
    final inc= d(s(60, 69));            // inclination i
    final ecc= d(s(70, 79));            // eccentricity e
    final sma= d(s(92, 103));           // semi-major axis a

    return _MpcRow(des, H, sma, ecc, inc);
  }
}

class _IsolateArg {
  final SendPort sendPort;
  final String text;
  final int? maxRows;
  _IsolateArg(this.sendPort, this.text, this.maxRows);
}
*/
