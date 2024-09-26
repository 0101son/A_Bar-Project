import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:chat/Data/database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:collection';

enum SystemState { idle, ready, active, finish }

class BluetoothManager {
  static final BluetoothManager _bluetoothManager =
      BluetoothManager._internal();

  factory BluetoothManager() {
    return _bluetoothManager;
  }

  BluetoothManager._internal();

  SystemState? systemState;

  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _device;
  BluetoothConnection? _connection;

  bool get isConnected => _connection?.isConnected ?? false;

  Function? onConnectionChanged; //

  final Queue<String> _messageQueue = Queue<String>();
  StreamSubscription<Uint8List>? sub;
  Future<void> startBluetoothConnection() async {
    await requestBluetoothPermission();

    await searchForDevice();

    await maintainConnection();
  }

  Future<void> requestBluetoothPermission() async {
    while (await Permission.bluetoothConnect.status.isDenied) {
      //print("bluetoothConnect request");
      await Permission.bluetoothConnect.request();
    }

    while (await Permission.bluetooth.status.isDenied) {
      //print("bluetooth request");
      await Permission.bluetooth.request();
    }

    while (await Permission.bluetoothScan.status.isDenied) {
      //print("bluetoothScan request");
      await Permission.bluetoothScan.request();
    }

    //print("bluetooth permission OK");
  }

  Future<void> searchForDevice() async {
    while (_device == null) {
      //print("Searching for HC-06...");
      _devicesList = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var device in _devicesList) {
        if (device.name == "HC-06") {
          //print("HC-06 found");
          _device = device;
          break;
        }
      }
      if (_device == null) {
        //print("HC-06 not found");
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  Future<void> maintainConnection() async {
    while (true) {
      if (_connection == null || !_connection!.isConnected) {
        //print("connection lost - restart connection");
        try {
          _connection = await BluetoothConnection.toAddress(_device!.address);
          sub = _connection!.input!.listen((event) {
            //print("message found");
            String receivedData = utf8.decode(event);
            handleData(receivedData);
          });
          //print("connection success");
          if (_messageQueue.isNotEmpty) {
            //print("queue not empty - ${_messageQueue.length} - send messages");
            _sendMessages();
          }
        } catch (e) {
          //print("connection failed");
        }
      } else {}
      onConnectionChanged?.call();
      await Future.delayed(const Duration(seconds: 3));
    }
  }

/*  Future<bool> checkConnection() async {
    if (_connection == null) {
      print("checkConnection: _connection is null");
      return false;
    }

    if (_connection!.input == null){
      print("checkConnection: input is null");
      return false;
    }

      // 통신 상태 확인 메시지 전송
    Uint8List checkData =
        Uint8List.fromList(utf8.encode("CHECK_CONNECTION\n"));
    _connection!.output.add(checkData);

    // 응답 대기 및 처리
    StreamSubscription? subscription;
    final responseCompleter = Completer<bool>();

    subscription = _connection!.input!.listen((data) {
      String response = utf8.decode(data);
      if (response.contains("CONNECTION_OK")) {
        // StreamSubscription 취소 및 Completer에 true 전달
        subscription?.cancel();
        responseCompleter.complete(true);
      }
    });

    // 최대 2초 동안 응답 대기
    bool isConnected = await Future.any([
      responseCompleter.future,
      Future.delayed(Duration(seconds: 2), () => false)
    ]);

    // 2초가 지나도 응답이 없으면 StreamSubscription 취소
    if (!responseCompleter.isCompleted) {
      subscription?.cancel();
    }

    return isConnected;
  }*/

  String buffer = '';

  void handleData(String signal) {
    buffer += signal;
    //print("buffer: $buffer");
    int newlineIndex = buffer.indexOf('\n');
    while (newlineIndex != -1) {
      String completeData = buffer.substring(0, newlineIndex).trim();
      handleArduinoSignal(completeData);
      buffer = buffer.substring(newlineIndex + 1);
      newlineIndex = buffer.indexOf('\n');
    }
  }

  void handleArduinoSignal(String signal) {
    switch (signal) {
      case "idle":
        systemState = SystemState.idle;
        break;
      case "ready":
        systemState = SystemState.ready;
        break;
      case "active":
        systemState = SystemState.active;
        break;
      case "finish":
        systemState = SystemState.finish;
        break;
    }
  }

  Future<void> waitState(SystemState state) async {
    while (systemState != state) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
  }

  void send(String message) {
    _messageQueue.add(message);
    //print("queue length: ${_messageQueue.length}");
    //print("try send $message");

    //print("_connection: $_connection");
    if (_connection == null) {
      //print("send fail: connection null ");
      return;
    }

    if (!_connection!.isConnected) {
      //print("send fail: not connected");
      return;
    }
    _sendMessages();
  }

  void _sendMessages() async {
    //print("Queue lengte: ${_messageQueue.length}");
    while (_messageQueue.isNotEmpty) {
      String message = _messageQueue.removeFirst();
      Uint8List sendData = Uint8List.fromList(utf8.encode(message));
      _connection!.output.add(sendData);
      //print("textOut: $message , Queue length: ${_messageQueue.length}");
    }
  }

  String order(Cocktail cocktail) {
    var mix = cocktail.mix.map((e) => e.toJson()).toList();
    var recipeJson = jsonEncode({"recipe": mix});

    send("$recipeJson\n");
    //print("order: ${cocktail.name}");
    return recipeJson;
  }
}
