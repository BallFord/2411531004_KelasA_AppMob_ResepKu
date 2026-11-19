import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/error_view.dart';
import 'package:resepku/widgets/recipe_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Future<List<Recipe>>? _searchFuture;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    setState(() {
      _lastQuery = query;
      _searchFuture = context.read<RecipeService>().searchRecipes(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari nama resep (misal: Chicken)...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            tooltip: 'Cari',
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _searchFuture == null
          ? const Center(
              child: Text('Ketik kata kunci resep lalu tekan Enter.'),
            )
          : FutureBuilder<List<Recipe>>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'Gagal mencari resep.\n${snapshot.error}',
                    onRetry: () => _performSearch(_lastQuery),
                  );
                }

                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada resep yang cocok untuk "$_lastQuery".',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      RecipeTile(recipe: results[index]),
                );
              },
            ),
    );
  }
}