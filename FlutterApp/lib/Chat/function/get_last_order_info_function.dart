import 'package:chat/Data/database.dart';

Map<String, dynamic> getLastOrderInfo(Map<String, dynamic> args) {
  InDatabase inDatabase = InDatabase();
  var lastOrder = inDatabase.orders.last.cocktail;
  return {"name": lastOrder.name, "recipe": lastOrder.recipe.toString()};
}
