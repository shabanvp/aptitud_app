import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/store_item.dart';
import '../../services/mock_data_service.dart';
import '../../providers/game_state_provider.dart';
import '../../core/theme.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeItems = MockDataService.storeItems;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Loot Store',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accent),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: storeItems.length,
            itemBuilder: (context, index) {
              return _StoreItemCard(item: storeItems[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  final StoreItem item;

  const _StoreItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameStateProvider>(context);
    final canAfford = gameState.coins >= item.cost;
    final meetsLevel = gameState.level >= item.minLevelRequired;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: canAfford ? AppTheme.primary : Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(item.itemType),
            size: 48,
            color: meetsLevel ? AppTheme.accent : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.coins, size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              Text('${item.cost}', style: TextStyle(color: canAfford ? Colors.white : AppTheme.error)),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: meetsLevel && canAfford ? AppTheme.primary : Colors.grey,
                ),
                onPressed: meetsLevel && canAfford
                    ? () {
                        gameState.spendCoins(item.cost);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Purchased ${item.name}!')),
                        );
                      }
                    : null,
                child: Text(
                  meetsLevel ? 'BUY' : 'LVL ${item.minLevelRequired}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'FRAME':
        return Icons.crop_square;
      case 'THEME':
        return Icons.color_lens;
      case 'LIFE_REFILL':
        return Icons.favorite;
      case 'AVATAR':
        return Icons.face;
      default:
        return Icons.star;
    }
  }
}
