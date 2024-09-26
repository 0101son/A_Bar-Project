class User {
  final int id;
  final String name;

  User({
    required this.id,
    required this.name,
  });
}

class Order {
  late int id;
  final int userId;
  final Cocktail cocktail;
  final DateTime timestamp;

  Order._({
    required this.id,
    required this.userId,
    required this.cocktail,
    required this.timestamp,
  });
}

enum Ingredient {
  grenadine,

  orangeJuice,
  pineappleJuice,
  lemonJuice,
  pinaColadaMix,
  limeJuice,
  coke,
  gingerAle,
}

Map<Ingredient, String> koreanIngredientNames = {
  Ingredient.grenadine: '크렌베리 주스',
  Ingredient.coke: '콜라',
  Ingredient.gingerAle: '진저 에일',
  Ingredient.orangeJuice: '오렌지 주스',
  Ingredient.pineappleJuice: '파인애플 주스',
  Ingredient.lemonJuice: '레몬 주스',
  Ingredient.pinaColadaMix: '피나콜라다 믹스',
  Ingredient.limeJuice: '라임 주스',
};

class Cocktail {
  String name;
  List<RecipeUnit> recipe;
  List<MixUnit> mix;

  // Custom Cocktail을 생성
  Cocktail({required this.recipe, required this.name, required this.mix});
}

enum Menu {
  shirleyTemple,
  virginSunrise,
  sunshine,
  virginCubaLibre,
  cinderella,
  verginPinaColada,
}

Map<Menu, String> koreanCocktailNames = {
  Menu.shirleyTemple: '셜리 템플',
  Menu.virginSunrise: '선라이즈',
  Menu.sunshine: '선샤인',
  Menu.virginCubaLibre: '버진 쿠바 리브레',
  Menu.cinderella: '신데렐라',
  Menu.verginPinaColada: '버진 피나콜라다',
};

class RecipeUnit {
  final Ingredient ingredient;
  final double ratio;

  RecipeUnit({required this.ingredient, required this.ratio});

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient.index,
      'ratio': ratio,
    };
  }
}

class MixUnit {
  final Ingredient ingredient;
  final int amount;

  MixUnit({required this.ingredient, required this.amount});

  Map<String, int> toJson() {
    return {
      'ingredient': ingredient.index,
      'amount': amount,
    };
  }
}

final recipeBook = {
  Menu.shirleyTemple: [
    RecipeUnit(ingredient: Ingredient.gingerAle, ratio: 8),
    RecipeUnit(ingredient: Ingredient.grenadine, ratio: 1),
  ],
  Menu.virginSunrise: [
    RecipeUnit(ingredient: Ingredient.orangeJuice, ratio: 8),
    RecipeUnit(ingredient: Ingredient.grenadine, ratio: 1),
  ],
  Menu.sunshine: [
    RecipeUnit(ingredient: Ingredient.pineappleJuice, ratio: 4),
    RecipeUnit(ingredient: Ingredient.orangeJuice, ratio: 2),
    RecipeUnit(ingredient: Ingredient.lemonJuice, ratio: 1),
    RecipeUnit(ingredient: Ingredient.grenadine, ratio: 2),
  ],
  Menu.virginCubaLibre: [
    RecipeUnit(ingredient: Ingredient.coke, ratio: 15),
    RecipeUnit(ingredient: Ingredient.limeJuice, ratio: 1),
  ],
  Menu.cinderella: [
    RecipeUnit(ingredient: Ingredient.orangeJuice, ratio: 1),
    RecipeUnit(ingredient: Ingredient.lemonJuice, ratio: 1),
    RecipeUnit(ingredient: Ingredient.pineappleJuice, ratio: 1),
  ],
  Menu.verginPinaColada: [
    RecipeUnit(ingredient: Ingredient.pineappleJuice, ratio: 1),
    RecipeUnit(ingredient: Ingredient.pinaColadaMix, ratio: 1),
  ],
};

class InDatabase {
  List<User> users = [];
  List<Order> orders = [];

  InDatabase._privateConstructor();

  static final InDatabase _instance = InDatabase._privateConstructor();

  factory InDatabase() {
    return _instance;
  }

  void addUser(User user) {
    users.add(user);
  }

  void addOrder(
      {required int userId, required Cocktail cocktail, DateTime? timestamp}) {
    int orderId = orders.length;
    Order newOrder = Order._(
      id: orderId,
      userId: userId,
      cocktail: cocktail,
      timestamp: DateTime.now(),
    );
    orders.add(newOrder);
  }

  User getUser(int userId) {
    return users.firstWhere((user) => user.id == userId);
  }

  Order getOrder(int orderId) {
    return orders.firstWhere((order) => order.id == orderId);
  }
}
