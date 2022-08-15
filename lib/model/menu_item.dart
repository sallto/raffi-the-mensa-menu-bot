import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class MenuItem{
  String dish;
  String category;
  MenuItem(this.dish,this.category);
}
