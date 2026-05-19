import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenvix/features/trash/data/models/trash_item_model.dart';

abstract class TrashLocalDataSource {
  Future<List<TrashItemModel>> getTrashItems();
  Future<void> saveTrashItems(List<TrashItemModel> items);
}

class TrashLocalDataSourceImpl implements TrashLocalDataSource {
  TrashLocalDataSourceImpl(this._prefs);
  final SharedPreferences _prefs;
  static const String _trashItemsKey = 'trash_items';

  @override
  Future<List<TrashItemModel>> getTrashItems() async {
    final jsonString = _prefs.getString(_trashItemsKey);
    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => TrashItemModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveTrashItems(List<TrashItemModel> items) async {
    final mapList = items.map((e) => e.toMap()).toList();
    final jsonString = json.encode(mapList);
    await _prefs.setString(_trashItemsKey, jsonString);
  }
}
