import 'package:shared_preferences/shared_preferences.dart';

class SpaceStorage {
  SpaceStorage._(this._prefs);

  static const _kSavedPeerIds = 'fitnet_space_saved_peer_ids';

  final SharedPreferences _prefs;

  static Future<SpaceStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SpaceStorage._(prefs);
  }

  Set<int> readSavedPeerIds() {
    final raw = _prefs.getStringList(_kSavedPeerIds) ?? const <String>[];
    return raw.map((e) => int.tryParse(e) ?? -1).where((e) => e > 0).toSet();
  }

  Future<void> writeSavedPeerIds(Set<int> ids) async {
    final list = ids.map((e) => e.toString()).toList()..sort();
    await _prefs.setStringList(_kSavedPeerIds, list);
  }
}

