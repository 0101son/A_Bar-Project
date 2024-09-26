import 'package:chat/Data/database.dart';
import 'package:chat/Arduino/bluetooth_manager.dart';
import 'package:chat/Chat/chat_manager.dart';
import 'package:chat/Data/inventory_manager.dart';

// 1. 입력 변환 함수
List<MixUnit> convertToMixUnits(
    List<Map<String, dynamic>> inputRecipe, int amount) {
  double totalRatio = 0;
  print("input recipe; $inputRecipe");
  for (var recipeUnit in inputRecipe) {
    Map<String, dynamic> unitMap = recipeUnit;
    if (unitMap['ratio'] != null) {
      if (unitMap['ratio'] is int) {
        totalRatio += (unitMap['ratio'] as int).toDouble();
      } else if (unitMap['ratio'] is double) {
        totalRatio += unitMap['ratio'] as double;
      }
    }
  }

  // Reverse the koreanIngredientNames map
  Map<String, Ingredient> reversedKoreanIngredientNames =
      koreanIngredientNames.map((k, v) => MapEntry(v, k));

  return List.generate(inputRecipe.length, (index) {
    Ingredient ingredient = reversedKoreanIngredientNames[
        inputRecipe[index]['ingredient'] as String]!;
    double ratio;
    if (inputRecipe[index]['ratio'] is int) {
      ratio = (inputRecipe[index]['ratio'] as int).toDouble();
    } else {
      ratio = inputRecipe[index]['ratio'] as double;
    }
    int calculatedAmount = (amount * ratio) ~/ totalRatio;

    return MixUnit(ingredient: ingredient, amount: calculatedAmount);
  });
}

List<RecipeUnit> convertToRecipeUnits(List<Map<String, dynamic>> inputRecipe) {
  // Reverse the koreanIngredientNames map
  Map<String, Ingredient> reversedKoreanIngredientNames =
      koreanIngredientNames.map((k, v) => MapEntry(v, k));

  return List.generate(inputRecipe.length, (index) {
    Ingredient ingredient = reversedKoreanIngredientNames[
        inputRecipe[index]['ingredient'] as String]!;
    double ratio;
    if (inputRecipe[index]['ratio'] is int) {
      ratio = (inputRecipe[index]['ratio'] as int).toDouble();
    } else {
      ratio = inputRecipe[index]['ratio'] as double;
    }

    return RecipeUnit(ingredient: ingredient, ratio: ratio);
  });
}

Map<String, dynamic> orderCocktail(Map<String, dynamic> args) {
  InDatabase inDatabase = InDatabase();
  BluetoothManager bluetoothManager = BluetoothManager();
  ChatManager chatManager = ChatManager();
  InventoryManager inventoryManager = InventoryManager();
  // 1. 입력받은 내용을 변수로 변환
  print("orderCocktail 함수 입력됨: $args");
  String cocktailName = args['name'];
  int cocktailAmount;
  if (args['amount'] == null) {
    cocktailAmount = 270;
  } else {
    cocktailAmount = args['amount'];
  }

  List<Map<String, dynamic>> cocktailRecipe =
      (args['recipe'] as List).cast<Map<String, dynamic>>();

  // 2. 입력받은 레시피를 재료 - ml 쌍의 리스트로 변환
  List<MixUnit> mixUnits = convertToMixUnits(cocktailRecipe, cocktailAmount);
  List<RecipeUnit> recipeUnits = convertToRecipeUnits(cocktailRecipe);

  Cocktail cocktail =
      Cocktail(recipe: recipeUnits, name: cocktailName, mix: mixUnits);

  // 3. 반환된 리스트로 json을 만듦
  bluetoothManager.order(cocktail);
  inDatabase.addOrder(userId: 0, cocktail: cocktail);
  chatManager.orderFinalized = true;
  for (MixUnit mixUnit in mixUnits) {
    if (inventoryManager.inventory[mixUnit.ingredient] != null) {
      double? currentAmount = inventoryManager.inventory[mixUnit.ingredient];
      inventoryManager.inventory[mixUnit.ingredient] =
          currentAmount! - mixUnit.amount;
    }
  }
  inventoryManager.updateMenuAvailability();

  return {"order success": cocktail.name};
}

/*
Map<String, dynamic> orderCocktail(Map<String, dynamic> args) {
  BluetoothManager bluetoothManager = BluetoothManager();
  InventoryManager inventoryManager = InventoryManager();
  ChatManager chatManager = ChatManager();
  print(args['cocktailName']);
  for (Menu menu in Menu.values){
    for (Menu menu in Menu.values) {
    {
      if (koreanCocktailNames[menu] == args['cocktailName']) {
        bluetoothManager.order(Cocktail.fromMenu(menu));
        print("order success");
        chatManager.orderFinalized = true;
        for (MixUnit mixUnit in recipeBook[menu]!) {
          if (inventoryManager.inventory[mixUnit.ingredient] != null) {
            int? currentAmount = inventoryManager.inventory[mixUnit.ingredient];
            inventoryManager.inventory[mixUnit.ingredient] =
                currentAmount! - mixUnit.ratio;
          }
        }
        inventoryManager.updateMenuAvailability();
        return {"order success": koreanCocktailNames[menu]};
      }
    }
  }
  }
  print("order failed");
  return {"order success": "주문이 실패했습니다. 메뉴와 정확히 일치하는 이름을 입력하세요"};
}
*/