import 'package:json_annotation/json_annotation.dart';
part 'menu_item.g.dart';

@JsonSerializable()
class MenuItem{
  String dish;
  String category;
  MenuItem(this.dish,this.category);
  // Necessary for automatic JSON generation.
  factory MenuItem.fromJson(Map<String,dynamic>json) => _$MenuItemFromJson(json);
  Map<String,dynamic> toJson() => _$MenuItemToJson(this);
}
