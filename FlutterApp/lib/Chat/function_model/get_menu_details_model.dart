import 'package:dart_openai/dart_openai.dart';

// getMenuDetails Function Model 인스턴스 생성
OpenAIFunctionModel getMenuDetailsModel = OpenAIFunctionModel.withParameters(
  name: 'getMenuDetails',
  description:
      'Model to retrieve detailed recipe for each menu item. ratio is ratio, not ml. do not mention reccipe before user needs it',
  parameters: [
    OpenAIFunctionProperty.string(
      name: 'args',
      description: 'this function don\'t need argument',
      isRequired: false,
    ),
  ],
);
