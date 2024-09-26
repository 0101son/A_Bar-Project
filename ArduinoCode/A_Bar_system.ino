#include <SoftwareSerial.h>
#include <Arduino_JSON.h>


#include "HX711.h"



uint8_t dataPin = 40;
uint8_t clockPin = 41;

uint32_t start, stop;
volatile float f;

HX711 myScale;

int flushToggle = 0; // 0, 1, 2, 3 중 하나의 값을 가집니다
int suckBackToggle = 0; 

int EMO1 = 22; // 모든 펌프 토출 (플러싱용)
int EMO2 = 23; // 모든 펌프 석백 (석백용)

#define TRIG 11  //TRIG 핀 설정 (초음파 보내는 핀)

#define ECHO 10  //ECHO 핀 설정 (초음파 받는 핀)

void setup() {
  
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);

  Serial.begin(9600);  //시리얼 통신 주기 설정

  Serial.println("Initializing system...");  //이키마스~

  Serial.println(__FILE__);               //  use scale.set_offset(122336); and scale.set_scale(1101.373413);
  Serial.print("LIBRARY VERSION: ");
  Serial.println(HX711_LIB_VERSION);
  Serial.println();
  myScale.begin(dataPin, clockPin);  //로드셀 설정
  myScale.set_offset(156756);
  myScale.set_scale(1100.878051);
  myScale.tare();
 
  for(int i=0; i<8; i++){  //펌프 모터 설정
    pinMode(getSpeedPinNumber(i),OUTPUT);
    pinMode(getOutPinNumber(i),OUTPUT);
    pinMode(getInPinNumber(i),OUTPUT);
  }

  pinMode(EMO1, INPUT_PULLUP);
  pinMode(EMO2, INPUT_PULLUP);
  
  Serial.println("Setup ready");
}

void loop() {
  while(digitalRead(EMO1)==LOW) // EMO1 누르는 동안 플러싱
  {
    flushTwo();
    if(digitalRead(EMO1)==HIGH)
    {
        suckBackToggle = flushToggle; 
        flushToggle = (flushToggle + 1) % 4; // 다음 그룹으로 이동하거나 처음 그룹으로 롤백
        pause(0);
        break;
    }
  }

  while(digitalRead(EMO2)==LOW) // EMO2 누르는 동안 석백
  {
    suckBackTwo();
    if(digitalRead(EMO2)==HIGH)
    {
        pause(0);
        break;
    }
  }

  if (Serial.available()) {
    Serial.println("get input");
    String input = Serial.readStringUntil('\n');
    Serial.println(input);
    JSONVar myObject = JSON.parse(input);

    // JSON 파싱에 문제가 있을 경우
    if (JSON.typeof(myObject) == "undefined") {
      Serial.println("Parsing input failed!");
      return;
    }

    if (myObject.hasOwnProperty("recipe")) {
      JSONVar recipeArray = myObject["recipe"];
      int recipeLen = recipeArray.length();
      for (int i = 0; i < recipeLen; i++) {
        JSONVar ingredient = recipeArray[i];
        Serial.print("Ingredient: ");
        Serial.print(ingredient["ingredient"]);
        Serial.print(", Amount: ");
        Serial.println(ingredient["amount"]);
      }

      detectCupAndPour(recipeArray);
    }
  }


  if (Serial.available()) {
    Serial.write(Serial.read());  //시리얼 모니터 내용을 블루추스 측에 WRITE
  }
}

void flushTwo(){
    int startIdx = flushToggle * 2;
    for(int i = startIdx ; i < startIdx+2; i++){
        digitalWrite(getSpeedPinNumber(i),HIGH);
        digitalWrite(getOutPinNumber(i),HIGH);
        digitalWrite(getInPinNumber(i),LOW);
    }
    delay(100);
}

void suckBackTwo(){
    int startIdx = suckBackToggle * 2;
    for(int i = startIdx ; i < startIdx+2; i++){
        digitalWrite(getSpeedPinNumber(i),HIGH);
        digitalWrite(getOutPinNumber(i),LOW);
        digitalWrite(getInPinNumber(i),HIGH);
    }
    delay(100);
}
void detectCupAndPour(JSONVar recipeArray) {
  // 1. 컵 감지
  Serial.println("ready");
  Serial.println("ready - waiting for cup");
  waitUntilCupDetection(true, 20);
  // 2. 조주 시작
  Serial.println("active");

  Serial.println("active - pouring");
  executeRecipe(recipeArray);

  // 3. 조주 완료
  Serial.println("finish");
  Serial.println("finish - waiting for take");
  waitUntilCupDetection(false, 20);


  
  Serial.println("idle");
  Serial.println("idle - waiting for next order");
}

void waitUntilCupDetection(bool cup, int distance) {

  int stack = 0;
  bool loadDetection = false;
  bool ultraSoundDetection = false;
  myScale.tare();
  while (stack < 15) {
    long duration, distanceDetection;


    digitalWrite(TRIG, LOW);

    delayMicroseconds(2);

    digitalWrite(TRIG, HIGH);

    delayMicroseconds(10);

    digitalWrite(TRIG, LOW);



    duration = pulseIn(ECHO, HIGH);  //물체에 반사되어돌아온 초음파의 시간을 변수에 저장합니다.





    //34000*초음파가 물체로 부터 반사되어 돌아오는시간 /1000000 / 2(왕복값이아니라 편도값이기때문에 나누기2를 해줍니다.)

    //초음파센서의 거리값이 위 계산값과 동일하게 Cm로 환산되는 계산공식 입니다. 수식이 간단해지도록 적용했습니다.

    distanceDetection = duration * 17 / 1000;







    //PC모니터로 초음파 거리값을 확인 하는 코드 입니다.
    //Serial.print("\nDIstance : ");

    //Serial.print(distance);  //측정된 물체로부터 거리값(cm값)을 보여줍니다.

    //Serial.println(" Cm");
    bool prevloadDetection = loadDetection;
    loadDetection = myScale.get_units() > 0.5;
    if(prevloadDetection != loadDetection){
      Serial.print("loadDetection: ");
      Serial.println(loadDetection);
    } 
    bool prevultraSoundDetection = ultraSoundDetection;
    ultraSoundDetection = distanceDetection < distance;
    
    if(prevultraSoundDetection != ultraSoundDetection){
      Serial.print("ultraSoundDetection: ");
      Serial.println(ultraSoundDetection);
    } 

    if ((loadDetection == cup) && (ultraSoundDetection == cup)) {
      stack++;
    } else {
      stack = 0;
    }
    //Serial.print("loadDetection: ");
    //Serial.println(loadDetection);
    //Serial.print(", ultraSoundDetection: ");
    //Serial.println(ultraSoundDetection);
    //Serial.print(", stack: ");
    //Serial.println(stack);
  }
  
  delay(5000);
  myScale.tare();
}

void executeRecipe(JSONVar recipeArray) {
  int recipeLen = recipeArray.length();
  for (int i = 0; i < recipeLen; i++) {
    JSONVar mixUnit = recipeArray[i];
    int ingredientNumber = mixUnit["ingredient"];
    int amount = mixUnit["amount"];
    
    Serial.print("Ingredient: ");
    Serial.print(mixUnit["ingredient"]);
    Serial.print(", Amount: ");
    Serial.println(mixUnit["amount"]);
    build(ingredientNumber,amount);
  }
}

void build(int ingredientNumber, int amount){
  Serial.print("start build: ");
  myScale.tare();
  suckBack(ingredientNumber,200);
  Serial.println(myScale.get_offset());
  Serial.println(myScale.get_scale());
  Serial.print("tared: ");
  Serial.println(myScale.get_units());
  float error = 1000;
  float p = 5;
  bool boost = false;
  int boostCount = 0;
  int minimumCount = 0;
  float i = 1.5;
  int minimumTarget = 10;
  while(error>0.1){
    float unit = myScale.get_units();
    error = amount - unit;

    minimumCount++;
    if(boost) boostCount++;

    int drive;

    if(error*p>255){
      drive = 255;
    }else{
      if(boost == false){
        boost = true;
      }
      drive = error*p + boostCount*i;
      if(drive >= 255) drive = 255;
    }

    if(minimumCount >= 150){
      if(minimumTarget > unit){
         error = 0;  // 강제 정지
      }else{
        minimumTarget = amount + 10;
        minimumCount = 0;
      }
    }
    
    pour(ingredientNumber,drive);
    Serial.print("unit: ");
    Serial.print(unit);
    Serial.print(", error: ");
    Serial.print(error);
    Serial.print(", minimumCount: ");
    Serial.print(minimumCount);
    Serial.print(", drive: ");
    Serial.println(drive);
  }
  suckBack(ingredientNumber,800);
  pause(0);
}

void pour(int ingredientNumber, int drive){
  analogWrite(getSpeedPinNumber(ingredientNumber), drive);
  digitalWrite(getOutPinNumber(ingredientNumber), HIGH);
  digitalWrite(getInPinNumber(ingredientNumber), LOW);
}

void suckBack(int ingredientNumber, int time){
  Serial.print(ingredientNumber);
  Serial.println(" 석백...");
  digitalWrite(getSpeedPinNumber(ingredientNumber), HIGH);
  digitalWrite(getOutPinNumber(ingredientNumber), LOW);
  digitalWrite(getInPinNumber(ingredientNumber), HIGH);
  delay(time);
}

void pause(int delayTime){
  for(int i = 0; i< 8; i++){
    digitalWrite(getSpeedPinNumber(i), LOW);
    digitalWrite(getOutPinNumber(i), LOW);
    digitalWrite(getInPinNumber(i), LOW);
  }
  delay(delayTime);
}

int getSpeedPinNumber(int ingredientNumber){
  return ingredientNumber + 2;
}

int getOutPinNumber(int ingredientNumber){
  return 24 + 2*ingredientNumber;
}

int getInPinNumber(int ingredientNumber){
  return 24 + 2*ingredientNumber + 1;
}