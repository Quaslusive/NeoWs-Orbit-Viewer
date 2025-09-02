import 'package:flutter/foundation.dart';
import 'package:neows_app/service/bookmarks_service.dart';

class BookmarksController extends ChangeNotifier {
  final BookmarksService svc;
  BookmarksController(this.svc);

  Set<int> _ids = {};
  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    _ids = await svc.get();
    _ready = true;
    notifyListeners();
  }

  bool isBookmarked(int id) => _ids.contains(id);

  Future<void> toggle(int id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    await svc.save(_ids);
    notifyListeners();
  }

  Future<void> restore(Set<int> previous) async {
    _ids = {...previous};
    await svc.save(_ids);
    notifyListeners();
  }

  Set<int> snapshot() => {..._ids};
}
