import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';

void main() {
  group('Recipe.fromJson', () {
    test('membaca rating int (5) sebagai double (5.0) dan memberi nilai bawaan untuk field yang hilang', () {
      final jsonMinimal = <String, dynamic>{
        'id': 99,
        'name': 'Resep Uji Coba',
        'rating': 5, // bertipe int dari JSON
      };

      final recipe = Recipe.fromJson(jsonMinimal);

      expect(recipe.id, 99);
      expect(recipe.name, 'Resep Uji Coba');
      expect(recipe.rating, isA<double>());
      expect(recipe.rating, 5.0);

      // Memastikan field yang tidak ada di JSON mendapat nilai bawaan tanpa error
      expect(recipe.cuisine, isA<String>());
      expect(recipe.difficulty, isA<String>());
      expect(recipe.servings, isA<int>());
      expect(recipe.caloriesPerServing, isA<int>());
      expect(recipe.image, isA<String>());
      expect(recipe.ingredients, isEmpty);
      expect(recipe.instructions, isEmpty);
    });
  });

  group('RecipeService.fetchRecipes', () {
    test('mengembalikan List<Recipe> dari respons palsu berstatus 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/recipes');
        final fakeResponse = jsonEncode({
          'recipes': [
            {
              'id': 1,
              'name': 'Nasi Goreng Spesial',
              'cuisine': 'Indonesian',
              'difficulty': 'Easy',
              'prepTimeMinutes': 10,
              'cookTimeMinutes': 15,
              'servings': 2,
              'caloriesPerServing': 450,
              'rating': 4.8,
              'image': 'https://example.com/nasgor.jpg',
              'ingredients': ['Nasi', 'Telur', 'Kecap'],
              'instructions': ['Tumis bumbu', 'Masukkan nasi'],
            },
            {
              'id': 2,
              'name': 'Soto Ayam',
              'cuisine': 'Indonesian',
              'rating': 5,
            },
          ],
        });
        return http.Response(fakeResponse, 200);
      });

      final service = RecipeService(client: mockClient);
      final recipes = await service.fetchRecipes();

      expect(recipes, hasLength(2));
      expect(recipes[0].name, 'Nasi Goreng Spesial');
      expect(recipes[0].totalTimeMinutes, 25);
      expect(recipes[1].name, 'Soto Ayam');
      expect(recipes[1].rating, 5.0);
    });

    test('melempar RecipeServiceException jika server merespons status 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = RecipeService(client: mockClient);

      expect(
        () => service.fetchRecipes(),
        throwsA(isA<RecipeServiceException>()),
      );
    });
  });
}