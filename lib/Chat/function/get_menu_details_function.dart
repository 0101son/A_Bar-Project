import 'package:chat/Data/database.dart';

Map<String, dynamic> getMenuDetails(Map<String, dynamic> args) {
  Map<String, List<Map<String, dynamic>>> menuDetails = {};
  for (Menu menu in Menu.values) {
    List<Map<String, dynamic>> recipeDetails = [];
    print('looking for $menu');
    if (recipeBook.containsKey(menu)) {
      for (RecipeUnit mixUnit in recipeBook[menu]!) {
        recipeDetails.add({
          'ingredient': koreanIngredientNames[mixUnit.ingredient]!,
          'ratio': mixUnit.ratio
        });
      }
    }

    menuDetails[koreanCocktailNames[menu]!] = recipeDetails;
  }
  print('getMenuDetails: finish');
  return menuDetails;
}
