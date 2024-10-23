
# A_Bar, AI Bartender 
<img src="https://github.com/user-attachments/assets/d127a8e9-2bae-4281-8ff8-975ea6787494" width="30%" />


**AI Bartender A_Bar** is an automated cocktail recommendation and serving system that uses AI to provide personalized cocktail options based on user preferences.

## Project Motivation

Many people find it challenging to select a cocktail due to the overwhelming variety available. This project aims to solve that problem by using AI to recommend and serve cocktails, considering individual preferences and tastes.

## Features

- **Cocktail Recommendations**: Users can ask for cocktail suggestions based on their preferences.
- **Customization**: Modify ingredients and quantities via conversational interaction.
- **Real-Time Feedback**: Sensors provide real-time feedback to ensure consistency and quality.

## Demo
[https://youtu.be/1Tw2JCakhj0](https://youtu.be/1Tw2JCakhj0)

## Project Structure

### Hardware
<img src="https://github.com/user-attachments/assets/7e162ba6-bd22-40c7-8482-201de7557039" width="30%" />


1. **Manufacturing Unit (Level 1)**
   - Components: 2kg Load Cell, HC-SR04 Ultrasonic Sensor
   - Purpose: Sensing the presence of a cup and providing measured liquid quantities.

2. **Operational Unit (Level 2)**
   - Components: 12V DC Diaphragm Pump, Silicone Tubes
   - Purpose: Driving fluid through tubes for cocktail creation.

3. **Control Unit (Level 3)**
   - Components: Arduino Mega, L298N Motor Driver, HX711 Load Cell Amplifier, HC-06 Bluetooth Module
   - Purpose: Controlling the pumps and motors to deliver the correct ingredients.

### Software
- **Interactive User Interface**:
   - Uses a tablet PC as a kiosk, allowing users to input their order via natural language.
   - Text-to-Speech (TTS) and Speech-to-Text (STT) functionalities are integrated for accessibility.
  
- **AI and Natural Language Processing**:
   - Uses the GPT model through the Chat GPT API to process user inputs, recommend custom recipes, and manage orders.
  
- **Bluetooth Communication**:
   - Orders and status updates are transmitted between the kiosk and the control unit via Bluetooth serial communication.

- **Feedback Control**:
   - Load cells and sensors are used to ensure accurate measurements and quality control during cocktail preparation.


## Improvements & Future Plans

- **Improved Reliability**: Replace gear pumps with diaphragm pumps for consistent pressure.
- **Database Integration**: Introduce a relational database to store and manage user preferences securely.
- **Cocktail Technique Modules**: Future development will include advanced modules for techniques like shaking and stirring.

## Contributors

- **Juyoung Son** - Team Leader, Software Engineering
- **Yongkyun Yu** - Hardware Design and Fabrication
- **Gunhee Lee** - Planning and Prototyping
