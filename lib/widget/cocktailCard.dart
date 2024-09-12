import 'package:flutter/material.dart';
import 'package:chat/Data/database.dart';
import 'package:chat/Data/inventory_manager.dart';

class CocktailCard extends StatelessWidget {
  final String imageUrl;
  final Menu menu;

  const CocktailCard({super.key, required this.imageUrl, required this.menu});

  @override
  Widget build(BuildContext context) {
    final inventoryManager = InventoryManager(); // assuming singleton
    final isAvailable = inventoryManager.menuEnable[menu] ?? false;
    final menuName = koreanCocktailNames[menu]!;
    final displayText = isAvailable ? menuName : "$menuName \n(재고 없음)";
    final opacity = isAvailable ? 1.0 : 0.2;
    return SizedBox(
      width: 20,
      height: 70,
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imageUrl),
                fit: BoxFit.cover,
                opacity: opacity,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            height: 50,
            child: Center(
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
