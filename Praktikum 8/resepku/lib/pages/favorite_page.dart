import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/widgets/recipe_image.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Semua Favorit'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua resep dari daftar favorit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<FavoriteProvider>().clear();
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorite = context.watch<FavoriteProvider>();
    final items = favorite.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Hapus semua',
            onPressed: favorite.count == 0
                ? null
                : () => _showClearConfirmationDialog(context),
          ),
        ],
      ),
      body: favorite.count == 0
          ? const Center(
              child: Text(
                'Belum ada resep favorit.\nTekan ikon hati di daftar resep.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final recipe = items[index];
                return Dismissible(
                  key: ValueKey(recipe.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    context.read<FavoriteProvider>().toggle(recipe);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('${recipe.name} dihapus dari favorit'),
                        ),
                      );
                  },
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: RecipeImage(
                          url: recipe.image,
                          cacheWidth: 168,
                        ),
                      ),
                    ),
                    title: Text(recipe.name),
                    subtitle: Text(recipe.cuisine),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => favorite.toggle(recipe),
                    ),
                  ),
                );
              },
            ),
    );
  }
}