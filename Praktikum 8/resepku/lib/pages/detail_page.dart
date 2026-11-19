import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/services/recipe_service.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.recipe});
  final Recipe recipe;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late int _servings; // state lokal: hanya halaman ini yang butuh
  late String _recipeName;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings; // nilai awal dari data resep
    _recipeName = widget.recipe.name;
  }

  void _addServing() {
    setState(() => _servings++);
  }

  void _removeServing() {
    if (_servings > 1) {
      setState(() => _servings--);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _recipeName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Resep'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama resep baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.pop(context, trimmed);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || !mounted) return;

    final service = context.read<RecipeService>();
    try {
      final updated = await service.updateRecipe(widget.recipe.id, newName);
      if (!mounted) return;
      setState(() => _recipeName = updated.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama resep diperbarui menjadi "${updated.name}".'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah nama: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: Text('Yakin ingin menghapus "$_recipeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final service = context.read<RecipeService>();
    try {
      final isDeleted = await service.deleteRecipe(widget.recipe.id);
      if (!mounted) return;
      if (isDeleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$_recipeName" berhasil dihapus.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus resep: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalCalories = recipe.caloriesPerServing * _servings;
    final isFavorite = context.watch<FavoriteProvider>().isFavorite(recipe);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            actions: [
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () => context.read<FavoriteProvider>().toggle(recipe),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editName();
                  } else if (value == 'delete') {
                    _confirmDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Ubah nama'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus'),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _recipeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${recipe.cuisine} • ${recipe.difficulty} • ${recipe.totalTimeMinutes} menit',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text('Porsi', style: textTheme.titleMedium),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: _servings > 1 ? _removeServing : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('$_servings', style: textTheme.titleLarge),
                          ),
                          IconButton.filledTonal(
                            onPressed: _addServing,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total kalori: $totalCalories kkal',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Text('Bahan', style: textTheme.titleLarge),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList.builder(
              itemCount: recipe.ingredients.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(recipe.ingredients[index]),
                );
              },
            ),
          ),
          // Judul "Langkah": widget biasa dibungkus SliverToBoxAdapter
          if (recipe.instructions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text('Langkah', style: textTheme.titleLarge),
              ),
            ),
          // Daftar langkah: lazy, sama seperti daftar bahan
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList.builder(
              itemCount: recipe.instructions.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  child: Text('${index + 1}'),
                ),
                title: Text(recipe.instructions[index]),
              ),
            ),
          ),
          // Ruang di bawah langkah terakhir
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}