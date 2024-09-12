import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:chat/Data/database.dart';
import 'package:chat/Data/inventory_manager.dart';
import 'package:chat/Chat/function_model/index.dart';
import 'package:chat/Chat/function/index.dart';

class ChatManager {
  static final ChatManager _chatManager = ChatManager._internal();

  factory ChatManager() {
    return _chatManager;
  }

  ChatManager._internal();
  InventoryManager inventoryManager = InventoryManager();
  static const key = '***************************************************';

  late List<OpenAIChatCompletionChoiceMessageModel> _chatLog;
  late bool orderFinalized;
  Future<void> getCompletion({bool? init}) async {
    print("now getting completion");
    for (int i = 0; i < _chatLog.length; i++) {
      print('log #$i: ${_chatLog[i]}');
    }
    OpenAIChatCompletionModel completion;
    if (init != null) {
      completion = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: _chatLog,
        functions: functions,
        functionCall: FunctionCall.forFunction("getMenuDetails"),
        temperature: 0,
      );
    } else {
      completion = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: _chatLog,
        functions: functions,
        temperature: 0,
      );
    }

    print("completion created");
    var message = completion.choices[0].message;

    _chatLog.add(message);
  }

  var functions = [orderCocktailModel, getMenuDetailsModel];

  String getMenuString() {
    List<String> enabledMenuList = [];
    List<String> disAbledMenuList = [];
    String menuString = '현재 ';
    for (Menu menu in Menu.values) {
      {
        var menuName = koreanCocktailNames[menu].toString();
        if (inventoryManager.menuEnable[menu]!) {
          enabledMenuList.add(menuName);
        } else {
          disAbledMenuList.add(menuName);
        }
      }
    }

    if (enabledMenuList.isEmpty) {
      menuString = '$menuString현재 재고 없음으로 제공할 수 있는 메뉴가 없습니다.';
    } else {
      menuString = '$menuString 제공할 수 있는 메뉴는 ';
      menuString = menuString + enabledMenuList.join(', ');
    }
    if (disAbledMenuList.isNotEmpty) {
      if (enabledMenuList.isNotEmpty) menuString += ', 그리고';
      menuString = '$menuString 재고 없음으로 제공할 수 없는 메뉴는 ';
      menuString = menuString + disAbledMenuList.join(', ');
    }
    menuString = '$menuString입니다.';

    if (disAbledMenuList.isNotEmpty) {
      menuString += ' 제공할 수 없는 메뉴에 대해서는 사용자에게 양해를 구하세요.';
    }
    return menuString;
  }

  Map<String, dynamic> getMenuInfo(Map<String, dynamic> args) {
    Map<String, List<String>> menuInfo = {};
    for (Menu menu in Menu.values) {
      List<String> recipe = [];
      print('looking for $menu');
      if (recipeBook.containsKey(menu)) {
        for (RecipeUnit mixUnit in recipeBook[menu]!) {
          recipe.add(koreanIngredientNames[mixUnit.ingredient]!);
        }
      }

      menuInfo[koreanCocktailNames[menu]!] = recipe;
    }
    print('getMenuInfo: finish');
    return menuInfo;
  }

  String getInitialSystemMessege() {
    String basicInstriction =
        '당신은 바텐더 시스템에서 고객의 취향의 맞는 칵테일을 찾아 주문을 넣는 역할을 하는 키오스크 시스템입니다. 사용자가 원할 경우에는 기존의 메뉴를 변형 하거나 혹은 새로운 레시피를 만들어 주문이 가능합니다. 사용자의 입력은 음성인식으로 입력되므로, 일부 오입력을 감안하셔야 합니다. 별 다른 언급이 없다면 메뉴의 레시피를 그대로 따라야 합니다.';
    InDatabase inDatabase = InDatabase();
    String userInfo;
    if (inDatabase.orders.isEmpty) {
      print("order data: ${inDatabase.orders}");
      userInfo = '현재 사용자의 이름은 손주영이고, 회원 계정을 처음 생성하셨습니다.';
    } else {
      print(
          "order data: ${inDatabase.orders.last.cocktail.name}, ${inDatabase.orders.last.cocktail.mix}, ${inDatabase.orders.last.cocktail.recipe}");
      userInfo =
          '현재 사용자의 이름은 손주영이고, 가장 최근에 시킨 칵테일은 ${inDatabase.orders.last.cocktail.name} 입니다.';
    }

    String menuInfo = getMenuString();

    return "$basicInstriction $userInfo $menuInfo 사용자에게 각 메뉴의 레시피를 언급하지 마세요. 대신 메뉴 이름들만 먼저 알려주세요.";
  }

  Future<String> initializeChat() async {
    print("chatManager initated");
    OpenAI.apiKey = key;
    _chatLog = [];
    orderFinalized = false;
    _chatLog.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: getInitialSystemMessege(),
      ),
    );
    print("getting response");
    await getResponse();
    print("initchat - ${_chatLog.last.content}");
    return _chatLog.last.content;
  }

  Future<String> getResponse(
      {String? input, OpenAIChatMessageRole? role, bool? init}) async {
    print("getResponse");
    // userInput이 있다면 chatLog에 추가
    if (input != null) {
      _chatLog.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: role!,
          content: input,
        ),
      );
    }
    print("getComplition");
    // 완성된 messege로 completion을 얻는다.
    await getCompletion(init: init);
    print("got Complition");
    // completion에 functionCall이 없다면 바로 출력한다.
    if (!_chatLog.last.hasFunctionCall) {
      print('content:${_chatLog.first.content} ${_chatLog.last.content}:');
      return _chatLog.last.content;
    }

    Map<String, Map<String, dynamic> Function(Map<String, dynamic>)>
        availableFunctions = {
      'orderCocktail': orderCocktail,
      'getMenuDetails': getMenuDetails,
    };
    FunctionCallResponse? response = _chatLog.last.functionCall;
    String? functionName = _chatLog.last.functionCall!.name;

    Map<String, dynamic> Function(Map<String, dynamic>)? functionToCall;
    functionToCall = availableFunctions[functionName];
    print('functionName: $functionName');
    print('functionToCall: $functionToCall');
    if (functionToCall != null) {
      var functionArgs = response?.arguments;
      Map<String, dynamic> functionResponse;

      if (functionArgs != null) {
        functionResponse = functionToCall(functionArgs);
      } else {
        functionResponse = functionToCall({});
      }
      print('orderFinalized: $orderFinalized');
      if (orderFinalized) return functionResponse["order success"];
      print('got function name: $functionName');
      print('got function response: ${jsonEncode(functionResponse)}');
      _chatLog.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.function,
          functionName: functionName,
          content: jsonEncode(functionResponse),
        ),
      );
    } else {
      _chatLog.add(
        const OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.function,
          content: "사용 가능한 함수를 사용하십시오.",
        ),
      );
    }

    await getCompletion();
    print("function response: ${_chatLog.last.content}");
    return _chatLog.last.content;
  }
}
