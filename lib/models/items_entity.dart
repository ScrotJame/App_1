import 'package:json_annotation/json_annotation.dart';

part 'items_entity.g.dart';

@JsonSerializable()
class ItemsEntity {
  final String? id;
  final String? name;
  final String? icon;
  final double? price;
  final int? stock;
  final String? description;

  ItemsEntity({
    this.id,
    this.name,
    this.price,
    this.stock = 0,
    this.description,
    this.icon});

  factory ItemsEntity.fromJson(Map<String, dynamic> json) => _$ItemsEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ItemsEntityToJson(this);
}