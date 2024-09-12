import 'package:chat/Data/database.dart';
import 'package:flutter/foundation.dart';

class InventoryManager {
  InventoryManager._privateConstructor() {
    initialize();
  }

  static final InventoryManager _instance =
      InventoryManager._privateConstructor();

  factory InventoryManager() {
    return _instance;
  }

  late final menuEnableNotifier = ValueNotifier<Map<Menu, bool>>(menuEnable);

  Map<Ingredient, double> maxInventory = {
    Ingredient.grenadine: 449,
    Ingredient.coke: 1800,
    Ingredient.gingerAle: 500,
    Ingredient.orangeJuice: 1000,
    Ingredient.pineappleJuice: 750,
    Ingredient.lemonJuice: 990,
    Ingredient.pinaColadaMix: 1000,
    Ingredient.limeJuice: 200,
  };

  late Map<Menu, bool> menuEnable;

  late Map<Ingredient, double> inventory;

  void initialize() {
    inventory = {};
    for (Ingredient ingredient in Ingredient.values) {
      inventory[ingredient] = 0;
    }
    menuEnable = {};
    for (Menu menu in Menu.values) {
      menuEnable[menu] = false;
    }

    menuEnableNotifier.value = menuEnable;
  }

  void refillSelectedIngredients(List<bool> selectionStatus) {
    for (int i = 0; i < selectionStatus.length; i++) {
      if (selectionStatus[i]) {
        inventory[Ingredient.values[i]] = maxInventory[Ingredient.values[i]]!;
      }
    }
    updateMenuAvailability();
  }

  final double minimumInventory = 70;

  void updateMenuAvailability() {
    for (Menu menu in Menu.values) {
      menuEnable[menu] = true;
      double totalRatio = 0;
      for (RecipeUnit recipeUnit in recipeBook[menu]!) {
        totalRatio += recipeUnit.ratio;
      }
      for (RecipeUnit recipeUnit in recipeBook[menu]!) {
        if (inventory[recipeUnit.ingredient]! <
            recipeUnit.ratio / totalRatio * 270 + minimumInventory) {
          menuEnable[menu] = false;
        }
      }
    }

    menuEnableNotifier.value = menuEnable;
  }
}
