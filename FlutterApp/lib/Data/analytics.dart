import 'package:chat/Data/database.dart';

class DataAnalytics {
  static MapEntry<String, int>? getMostFrequentlyOrderedCocktail(User user) {
    // 주어진 사용자의 주문을 모두 찾음
    List<Order> userOrders =
        InDatabase().orders.where((order) => order.userId == user.id).toList();

    // 사용자가 주문한 칵테일의 빈도를 저장하는 맵을 생성
    Map<String, int> cocktailFrequency = {};

    for (Order order in userOrders) {
      // 만약 맵에 이미 이 칵테일이 있다면, 카운트를 증가
      if (cocktailFrequency.containsKey(order.cocktail.name)) {
        cocktailFrequency[order.cocktail.name] =
            (cocktailFrequency[order.cocktail.name] ?? 0) + 1;
      } else {
        // 맵에 이 칵테일이 없다면, 카운트를 1로 시작
        cocktailFrequency[order.cocktail.name] = 1;
      }
    }

    // 가장 빈번하게 주문된 칵테일을 찾음
    var sortedEntries = cocktailFrequency.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value));

    // 가장 빈번하게 주문된 칵테일의 이름을 반환
    if (sortedEntries.isNotEmpty) {
      return sortedEntries[0];
    } else {
      // 빈 리스트인 경우 null 반환
      return null;
    }
  }
}
