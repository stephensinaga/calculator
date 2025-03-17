import 'package:hive/hive.dart';

part 'history_model.g.dart';

@HiveType(typeId: 0)
class HistoryModel extends HiveObject {
  @HiveField(0)
  String operation;

  @HiveField(1)
  String result;

  HistoryModel({required this.operation, required this.result});

  // Method copyWith agar bisa mengubah nilai
  HistoryModel copyWith({String? operation, String? result}) {
    return HistoryModel(
      operation: operation ?? this.operation,
      result: result ?? this.result,
    );
  }
}
