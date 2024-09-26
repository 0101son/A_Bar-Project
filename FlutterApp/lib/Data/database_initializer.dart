/*
import 'dart:math';
import 'package:chat/Data/database.dart';

abstract class ScenarioGenerator {
  final Random _random;
  final InDatabase _database;

  ScenarioGenerator(this._database) : _random = Random();

  // 각 시나리오 생성기가 반드시 구현해야 할 메서드
  void generate();
}

class RegularCustomerScenarioGenerator extends ScenarioGenerator {
  int weeklyVisits;
  int weeks;
  Menu favorateMenu;
  double otherDrinkProbability;
  String userName;

  RegularCustomerScenarioGenerator(
    InDatabase database, {
    this.userName = '',
    this.weeks = 4,
    this.weeklyVisits = 2,
    this.otherDrinkProbability = 0.2,
    this.favorateMenu = Menu.cinderella,
  }) : super(database);

  @override
  void generate() {
    int id = _database.users.length;
    if (userName == '') userName = 'user$id';
    var user = User(id: 1, name: userName);
    _database.addUser(user);

    int days = 7 * weeks;

    List<int> other = [];
    for (int i = 0; i < Menu.values.length; i++) {
      if (i != favorateMenu.index) other.add(i);
    }

    for (var i = 0; i < days; i++) {
      // 해당 날짜에 방문할 확률
      if (_random.nextDouble() < weeklyVisits / 7.0) {
        late Menu cocktail;

        DateTime time = DateTime.now().subtract(Duration(days: i + 1));
        // 다른 메뉴를 시킬 확률에 따라 다른 칵테일을 추가
        if (_random.nextDouble() < otherDrinkProbability) {
          cocktail = Menu.values[_random.nextInt(Menu.values.length)];
        } else {
          cocktail = favorateMenu;
        }

        // 주문 추가
        _database.addOrder(
            userId: id, cocktail: Cocktail.fromMenu(cocktail), timestamp: time);
      }
    }
    /*
    for (User user in _database.users) {
      print('${user.id} ${user.name}');
    }
    for (Order order in _database.orders) {
      print(
          '${order.id} ${order.userId} ${order.cocktail.name} ${order.timestamp}');
    }
    */
  }
}
*/