import 'package:dart_openai/dart_openai.dart';
import 'package:chat/Data/database.dart';

// amount 속성 정의
OpenAIFunctionProperty nameProperty = OpenAIFunctionProperty.string(
  name: 'name',
  description:
      'The name of the cocktail. Choose an appropriate name based on the context.',
  isRequired: true,
);

// amount 속성 정의
OpenAIFunctionProperty amountProperty = OpenAIFunctionProperty.number(
  name: 'amount',
  description:
      'Total amount of the cocktail in ml. default amount is 270(ml). Enter if only the user is mentioned',
);

// recipe의 각 항목에 대한 속성 정의
OpenAIFunctionProperty ingredientProperty = OpenAIFunctionProperty.string(
    name: 'ingredient',
    description:
        'Name of the ingredient. lemonJuice is very sour. if menu is too sour for customer, consider less lemon.',
    isRequired: true,
    enumValues:
        Ingredient.values.map((e) => koreanIngredientNames[e]!).toList());

OpenAIFunctionProperty ratioProperty = OpenAIFunctionProperty.number(
  name: 'ratio',
  description: 'Ratio of the ingredient in the cocktail.',
  isRequired: true,
);

// recipe 속성 정의
OpenAIFunctionProperty recipeProperty = OpenAIFunctionProperty.array(
  name: 'recipe',
  description: 'List of ingredients and their ratios',
  isRequired: true,
  items: OpenAIFunctionProperty.object(
    name: 'ingredientItem',
    properties: [ingredientProperty, ratioProperty],
  ),
);

// OpenAIFunctionModel 인스턴스 생성
OpenAIFunctionModel orderCocktailModel = OpenAIFunctionModel.withParameters(
  name: 'orderCocktail',
  description: 'Model to receive cocktail recipe',
  parameters: [nameProperty, amountProperty, recipeProperty],
);
