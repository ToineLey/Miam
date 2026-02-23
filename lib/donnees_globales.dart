import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. NOS VARIABLES GLOBALES ---
List<Map<String, dynamic>> mesRecettesGlobales = [
  {"nom": "Poulet rôti & Légumes", "rapide": false, "tempsExact": 45, "categorie": "Plat principal", "couleur": Colors.orange.value, "legumes": 50.0, "proteines": 50.0, "feculents": 0.0, "ingredients": ["Poulet", "Carottes", "Oignons"]},
  {"nom": "Pâtes au Pesto", "rapide": true, "tempsExact": 15, "categorie": "Plat principal", "couleur": Colors.green.value, "legumes": 10.0, "proteines": 10.0, "feculents": 80.0, "ingredients": ["Pâtes", "Pesto", "Parmesan"]},
  {"nom": "Pancakes Protéinés", "rapide": true, "tempsExact": 10, "categorie": "Petit-déjeuner", "couleur": Colors.brown.value, "legumes": 0.0, "proteines": 60.0, "feculents": 40.0, "ingredients": ["Oeufs", "Flocons d'avoine", "Lait"]},
];

final List<String> rayonsSupermarche = [
  "🥦 Fruits & Légumes", "🥩 Viandes & Poissons", "🧀 Frais & Laitier",
  "🍝 Épicerie Salée", "🍯 Épicerie Sucrée", "🥖 Boulangerie",
  "🌱 Rayon Végétarien", "📦 Autres"
];

Map<String, String> dictionnaireIngredientsGlobal = {
  "Poulet": "🥩 Viandes & Poissons", "Boeuf": "🥩 Viandes & Poissons", "Saumon": "🥩 Viandes & Poissons",
  "Oeufs": "🧀 Frais & Laitier", "Lait": "🧀 Frais & Laitier", "Beurre": "🧀 Frais & Laitier", "Parmesan": "🧀 Frais & Laitier",
  "Carottes": "🥦 Fruits & Légumes", "Oignons": "🥦 Fruits & Légumes", "Tomates": "🥦 Fruits & Légumes", "Salade": "🥦 Fruits & Légumes",
  "Pâtes": "🍝 Épicerie Salée", "Riz": "🍝 Épicerie Salée", "Huile d'olive": "🍝 Épicerie Salée", "Pesto": "🍝 Épicerie Salée",
  "Farine": "🍯 Épicerie Sucrée", "Flocons d'avoine": "🍯 Épicerie Sucrée", "Croûtons": "🥖 Boulangerie",
};

List<String> ingredientsBannisGlobaux = [];

// --- 2. FONCTIONS DE LECTURE ET SAUVEGARDE ---
Future<void> chargerDonneesLocales() async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.containsKey('recettes')) {
    List decode = jsonDecode(prefs.getString('recettes')!);
    mesRecettesGlobales = decode.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  if (prefs.containsKey('dictionnaire')) {
    Map decodeDico = jsonDecode(prefs.getString('dictionnaire')!);
    dictionnaireIngredientsGlobal = decodeDico.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  if (prefs.containsKey('bannis')) {
    List decodeBannis = jsonDecode(prefs.getString('bannis')!);
    ingredientsBannisGlobaux = decodeBannis.map((e) => e.toString()).toList();
  }
}

Future<void> sauvegarderDonneesLocales() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('recettes', jsonEncode(mesRecettesGlobales));
  await prefs.setString('dictionnaire', jsonEncode(dictionnaireIngredientsGlobal));
  await prefs.setString('bannis', jsonEncode(ingredientsBannisGlobaux));
}