/*
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neows_app/service/mpc_dat_to_csv.dart';
import 'package:neows_app/service/offline_mpc_service.dart';

class OfflineBootstrap {
  static const String _csvName = 'mpc_offline.csv';
  static const String _flagKey = 'mpc_csv_ready_v1';

  /// Ensures we have a local CSV generated from MPCORB.DAT.
  /// Returns the path to the CSV.
  static Future<String> ensureCsvReady() async {
    final dir = await getApplicationDocumentsDirectory();
    final csvPath = '${dir.path}/$_csvName';
    final prefs = await SharedPreferences.getInstance();

    final file = File(csvPath);
    final ready = prefs.getBool(_flagKey) ?? false;

    if (ready && await file.exists()) {
      return csvPath;
    }

    // Convert asset MPCORB.DAT -> CSV (could take seconds for large files)
    final csv = await MpcDatToCsv.convertAssetToCsv(
      assetPath: 'assets/MPCORB.DAT',
      // maxRows: 20000, // uncomment to cap during development
    );
    await file.writeAsString(csv);
    await prefs.setBool(_flagKey, true);
    return csvPath;
  }

  /// Load OfflineMpcService from the CSV we generated.
  static Future<OfflineMpcService> initOfflineService() async {
    final path = await ensureCsvReady();
    final service = OfflineMpcService();
    await service.loadFromAssets(path); // overload this to loadFromPath in your service
    return service;
  }
}
*/
