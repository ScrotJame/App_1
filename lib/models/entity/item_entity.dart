import 'package:json_annotation/json_annotation.dart';
part 'item_entity.g.dart';

@JsonSerializable()
class ItemEntity {
  final String? id;
  final String? name;
  final String? icon;
  final double? price;
  final int? stock;
  final String? description;
  final bool? isSynced;
  final DateTime? lastUpdated;

  const ItemEntity({
    this.id,
    this.name,
    this.icon,
    this.price,
    this.stock,
    this.description,
    this.isSynced,
    this.lastUpdated,
  });

  factory ItemEntity.fromJson(Map<String, dynamic> json) => _$ItemEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ItemEntityToJson(this);
}

@JsonSerializable()
class UserItemEntity {
  final String? userId;
  final String? itemId;
  final int? quantity;
  final ItemEntity? item;

  const UserItemEntity({
    this.userId,
    this.itemId,
    this.quantity,
    this.item,
  });

  factory UserItemEntity.fromJson(Map<String, dynamic> json) => _$UserItemEntityFromJson(json);
  Map<String, dynamic> toJson() => _$UserItemEntityToJson(this);
}