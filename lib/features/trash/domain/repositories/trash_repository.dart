import 'package:zenvix/features/trash/domain/entities/trash_item.dart';

abstract class TrashRepository {
  /// Retrieves all items currently in the trash.
  Future<List<TrashItem>> getTrashItems();

  /// Moves a file at the given [originalPath] to the trash.
  Future<void> moveToTrash(String originalPath);

  /// Restores a [TrashItem] to its original location.
  Future<void> restoreItem(TrashItem item);

  /// Permanently deletes a [TrashItem] from the device.
  Future<void> permanentlyDeleteItem(TrashItem item);

  /// Permanently deletes all items in the trash.
  Future<void> emptyTrash();
}
