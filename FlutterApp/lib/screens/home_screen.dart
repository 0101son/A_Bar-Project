import 'package:chat/Data/database.dart';
import 'package:chat/widget/cocktailCard.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:chat/Chat/chat_manager.dart';
import 'package:chat/Arduino/bluetooth_manager.dart';
import 'package:flutter/services.dart';
import 'package:chat/Data/inventory_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
//import 'package:qr_code_scanner/qr_code_scanner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  BluetoothManager bluetoothManager = BluetoothManager();
  final messageController = TextEditingController();
  late String response = '';
  bool connection = false;
  late ChatManager chatManager;
  final FocusNode _focusNode = FocusNode();
  InDatabase database = InDatabase();
  final FlutterTts tts = FlutterTts();

  //inventory
  InventoryManager inventoryManager = InventoryManager();

  //inventory UI
  List<bool> selectionStatus = List.generate(8, (index) => false);
  bool _showInventory = false;

  //stt
  SpeechToText speechToText = SpeechToText();
  bool isListening = false;

  @override
  void initState() {
    tts.setLanguage('ko-KR');
    tts.setSpeechRate(0.6);

    super.initState();
    setState(() {
      response = "에이바 잠에서 깨는중...";
    });
    inventoryManager.initialize();
    _showInventory = true;
    bluetoothManager.onConnectionChanged = () {
      setState(() {
        connection = bluetoothManager.isConnected;
        //print("connection: $connection");
      });
    };

    bluetoothManager.startBluetoothConnection();

    print("chat start");
    //RegularCustomerScenarioGenerator(InDatabase(), userName: 'user').generate();
    chatManager = ChatManager();
    print("chatManager active");
  }

  void restartChat() async {
    setState(() {
      response = "대화 다시 시작하는 중...";
    });
    chatManager.initializeChat().then((result) async {
      await tts.getVoices;
      tts.speak(result);
      setState(() {
        print("response: $result");
        response = result;
        _focusNode.requestFocus();
      });
    });
  }

  void getResponse(String userInput) async {
    await tts.getVoices;
    setState(() {
      response = "생각중...";
    });
    var botResponse = await chatManager.getResponse(
        input: userInput, role: OpenAIChatMessageRole.user);

    if (chatManager.orderFinalized) {
      messageController.clear();
      var cocktailName = botResponse;

      setState(() {
        InDatabase inDatabase = InDatabase();

        response =
            "$cocktailName의 주문이 완료되었습니다! 컵에 얼음을 가득 채운 뒤, 칵테일 장치 앞에 놓아주세요.";
        print("last order: ${inDatabase.orders.last.cocktail.recipe}");
        response += "\n---debug---\n";
        for (RecipeUnit recipeUnit in inDatabase.orders.last.cocktail.recipe) {
          response +=
              "\n 재료: ${koreanIngredientNames[recipeUnit.ingredient]}, 비율: ${recipeUnit.ratio}";
        }

        tts.speak(response);
      });

      await bluetoothManager.waitState(SystemState.active);

      setState(() {
        response = "컵을 꺼내지 마시고 다음 안내까지 잠시 기다려 주세요.";
        tts.speak(response);
      });

      await bluetoothManager.waitState(SystemState.finish);

      setState(() {
        response = "칵테일이 완성되었습니다. 컵을 꺼내주세요.";
        tts.speak(response);
      });

      await bluetoothManager.waitState(SystemState.idle);

      setState(() {
        response = "이용해주셔서 감사합니다. 즐거운 시간 보내세요!";
        tts.speak(response);
      });

      restartChat();
    } else {
      setState(() {
        response = botResponse;
        messageController.clear();
        _focusNode.requestFocus();
        tts.speak(response);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Icon(
                connection ? Icons.bluetooth : Icons.bluetooth_disabled,
                color: Colors.black,
              ),
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                constraints: const BoxConstraints(maxHeight: 550),
                // 너비에 맞게 자식 위젯의 크기를 조절
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width - 80, // 패딩을 고려한 최대 너비
                  ),
                  child: AutoSizeText(
                    response,
                    maxLines: 30, // 원하는 최대 줄 수를 지정합니다.
                    style: const TextStyle(
                      fontSize: 40,
                      height: 1.3,
                    ),
                    minFontSize: 12, // 최소 글자 크기를 지정합니다.
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: Menu.values.length,
                    itemBuilder: (context, index) {
                      return CocktailCard(
                        imageUrl:
                            'assets/images/menu$index.jpeg', // 경로를 assets 폴더로 변경
                        menu: Menu.values[index],
                      );
                    },
                  ),
                ),
              ),
              TextField(
                textInputAction: TextInputAction.send,
                onSubmitted: getResponse,
                focusNode: _focusNode,
                /*onChanged: (text) {
                  if (text[text.length] == '\n') {
                    getResponse;
                  }
                },*/
                controller: messageController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '대화를 입력해주세요 - 예: 메뉴 설명 더 해줘',
                    counterText: "반가워요"),
                style: const TextStyle(fontSize: 30),
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Opacity(
              opacity: 0.2,
              child: InkWell(
                onLongPress: () {
                  setState(() {
                    _showInventory = true;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              onPressed: () async {
                if (!isListening) {
                  var available = await speechToText.initialize();
                  if (available) {
                    setState(() {
                      isListening = true;
                      speechToText.listen(onResult: (result) {
                        setState(() {
                          messageController.text = result.recognizedWords;
                        });
                      });
                    });
                  }
                } else {
                  setState(() {
                    isListening = false;
                  });
                  speechToText.stop();
                }
              },
              child: isListening
                  ? const Icon(Icons.mic)
                  : const Icon(Icons.mic_off),
            ),
          ),
          if (_showInventory)
            Center(
              child: Container(
                width: 600,
                height: 600,
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          // This button refills all inventories
                          if (index == 8) {
                            return ElevatedButton(
                              child: const Text("모든 재고 채우기"),
                              onPressed: () {
                                setState(() {
                                  inventoryManager.inventory
                                      .forEach((key, value) {
                                    inventoryManager.inventory[key] =
                                        inventoryManager.maxInventory[key]!;
                                  });
                                });
                              },
                            );
                          }

                          // These buttons control the inventory of individual ingredients
                          Ingredient ingredient = Ingredient.values[index];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        if (inventoryManager.inventory
                                                .containsKey(ingredient) &&
                                            inventoryManager
                                                    .inventory[ingredient]! >
                                                100) {
                                          inventoryManager
                                                  .inventory[ingredient] =
                                              inventoryManager
                                                      .inventory[ingredient]! -
                                                  100;
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    koreanIngredientNames[ingredient]
                                        .toString()
                                        .split('.')
                                        .last,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        if (inventoryManager.inventory
                                                .containsKey(ingredient) &&
                                            inventoryManager
                                                    .inventory[ingredient]! <
                                                inventoryManager.maxInventory[
                                                        ingredient]! -
                                                    100) {
                                          inventoryManager
                                                  .inventory[ingredient] =
                                              inventoryManager
                                                      .inventory[ingredient]! +
                                                  100;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                '(${inventoryManager.inventory[ingredient]}/${inventoryManager.maxInventory[ingredient]})ml',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showInventory = false;
                          inventoryManager.updateMenuAvailability();
                          restartChat();
                        });
                      },
                      child: const Text('완료'),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
