import 'package:path/path.dart' as p;
import 'package:zenvix/features/trash/data/datasources/trash_local_data_source.dart';
import 'package:zenvix/features/trash/data/models/trash_item_model.dart';
import 'package:zenvix/features/trash/domain/entities/trash_item.dart';
import 'package:zenvix/features/trash/domain/repositories/trash_repository.dart';
import 'package:zenvix/features/trash/services/trash_file_service.dart';

class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._localDataSource, this._fileService);
  final TrashLocalDataSource _localDataSource;
  final TrashFileService _fileService;

  @override
  Future<List<TrashItem>> getTrashItems() => _localDataSource.getTrashItems();

  @override
  Future<void> moveToTrash(String originalPath) async {
    final size = await _fileService.getFileSize(originalPath);
    final fileName = p.basename(originalPath);
    final trashedPath = await _fileService.moveToTrash(originalPath);

    final itemModel = TrashItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalPath: originalPath,
      trashedPath: trashedPath,
      fileName: fileName,
      sizeBytes: size,
      deletedAt: DateTime.now(),
    );

    final items = await _localDataSource.getTrashItems();
    items.insert(0, itemModel);
    await _localDataSource.saveTrashItems(items);
  }

  @override
  Future<void> restoreItem(TrashItem item) async {
    await _fileService.restoreFile(item.trashedPath, item.originalPath);

    final items = await _localDataSource.getTrashItems();
    items.removeWhere((element) => element.id == item.id);
    await _localDataSource.saveTrashItems(items);
  }

  @override
  Future<void> permanentlyDeleteItem(TrashItem item) async {
    await _fileService.deleteFile(item.trashedPath);

    final items = await _localDataSource.getTrashItems();
    items.removeWhere((element) => element.id == item.id);
    await _localDataSource.saveTrashItems(items);
  }

  @override
  Future<void> emptyTrash() async {
    await _fileService.clearTrashDirectory();
    await _localDataSource.saveTrashItems([]);
  }
}
