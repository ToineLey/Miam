import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- CLASSES POUR LE PLANNING ---
class Repas {
  String type;
  Map<String, dynamic>? platSelectionne;
  int convives;

  Repas({required this.type, this.platSelectionne, required this.convives});

  Map<String, dynamic> toJson() => {
    'type': type,
    'platSelectionne': platSelectionne,
    'convives': convives,
  };

  factory Repas.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? platParse;
    try {
      if (json['platSelectionne'] != null) {
        platParse = Map<String, dynamic>.from(json['platSelectionne']);
        if (platParse['ingredients'] != null) {
          platParse['ingredients'] = (platParse['ingredients'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint("Erreur lecture plat : $e");
    }

    return Repas(
      type: json['type']?.toString() ?? "Midi",
      platSelectionne: platParse,
      convives: int.tryParse(json['convives']?.toString() ?? '2') ?? 2,
    );
  }
}

class Jour {
  String nomJour;
  bool estAffiche;
  List<Repas> repasDuJour;
  List<String> ingredientsExclus;
  List<String> ingredientsRequis;

  Jour({required this.nomJour, this.estAffiche = true, required this.repasDuJour, this.ingredientsExclus = const [], this.ingredientsRequis = const []});

  Map<String, dynamic> toJson() => {
    'nomJour': nomJour,
    'estAffiche': estAffiche,
    'repasDuJour': repasDuJour.map((r) => r.toJson()).toList(),
    'ingredientsExclus': ingredientsExclus,
    'ingredientsRequis': ingredientsRequis,
  };

  factory Jour.fromJson(Map<String, dynamic> json) {
    List<Repas> repasSecurises = [];
    try {
      if (json['repasDuJour'] != null) {
        for (var r in (json['repasDuJour'] as List)) {
          repasSecurises.add(Repas.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    } catch (e) {
      debugPrint("Erreur lecture repas du jour : $e");
    }

    return Jour(
      nomJour: json['nomJour']?.toString() ?? "Jour",
      estAffiche: json['estAffiche'] ?? true,
      repasDuJour: repasSecurises,
      ingredientsExclus: (json['ingredientsExclus'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ingredientsRequis: (json['ingredientsRequis'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// --- 1. NOS VARIABLES GLOBALES ---
List<Map<String, dynamic>> mesRecettesGlobales = [
  {"nom": "Poulet rôti & Légumes", "rapide": false, "tempsExact": 45, "categorie": "Plat principal", "couleur": Colors.orange.value, "legumes": 50.0, "proteines": 50.0, "feculents": 0.0, "ingredients": ["Poulet", "Carottes", "Oignons"]},
  {"nom": "Pâtes au Pesto", "rapide": true, "tempsExact": 15, "categorie": "Plat principal", "couleur": Colors.green.value, "legumes": 10.0, "proteines": 10.0, "feculents": 80.0, "ingredients": ["Pâtes", "Pesto", "Parmesan"]},
];

final List<String> rayonsSupermarche = [
  "🥦 Fruits & Légumes", "🥩 Viandes & Poissons", "🧀 Frais & Laitier",
  "🍝 Épicerie Salée", "🍯 Épicerie Sucrée", "🥖 Boulangerie", "🌱 Rayon Végétarien", "📦 Autres"
];

Map<String, String> dictionnaireIngredientsGlobal = {
  "Poulet": "🥩 Viandes & Poissons", "Carottes": "🥦 Fruits & Légumes", "Pâtes": "🍝 Épicerie Salée", "Pesto": "🍝 Épicerie Salée",
};

List<String> ingredientsBannisGlobaux = [];
List<Jour> semaineGlobale = [];
String jourDebutGlobal = "Lundi";
int convivesFoyerGlobal = 2;
List<String> exclusionsSemaineGlobales = [];
List<String> requisSemaineGlobaux = [];

// --- NOUVEAU : GESTION DU MODE SOMBRE ---
bool estModeSombreGlobal = false;
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);


// --- 2. GESTION DU FICHIER PHYSIQUE ET CACHE ---
Future<File> _obtenirFichierSauvegarde() async {
  final repertoire = await getApplicationDocumentsDirectory();
  return File('${repertoire.path}/mes_donnees_repas.json');
}

Future<void> chargerDonneesLocales() async {
  try {
    // 1. Charger les petits réglages depuis SharedPreferences (idéal pour le thème)
    final prefs = await SharedPreferences.getInstance();
    estModeSombreGlobal = prefs.getBool('modeSombre') ?? false;
    themeNotifier.value = estModeSombreGlobal ? ThemeMode.dark : ThemeMode.light;

    // 2. Charger les grosses données depuis le fichier JSON dur
    final fichier = await _obtenirFichierSauvegarde();
    if (!await fichier.exists()) return;

    String contenu = await fichier.readAsString();
    Map<String, dynamic> donnees = jsonDecode(contenu);

    if (donnees.containsKey('jourDebut')) jourDebutGlobal = donnees['jourDebut'];
    if (donnees.containsKey('convivesFoyer')) convivesFoyerGlobal = donnees['convivesFoyer'];

    if (donnees.containsKey('recettes')) {
      mesRecettesGlobales = (donnees['recettes'] as List).map((e) {
        Map<String, dynamic> plat = Map<String, dynamic>.from(e);
        if (plat['ingredients'] != null) plat['ingredients'] = (plat['ingredients'] as List).map((i) => i.toString()).toList();
        if (plat['legumes'] != null) plat['legumes'] = (plat['legumes'] as num).toDouble();
        if (plat['proteines'] != null) plat['proteines'] = (plat['proteines'] as num).toDouble();
        if (plat['feculents'] != null) plat['feculents'] = (plat['feculents'] as num).toDouble();
        return plat;
      }).toList();
    }
    if (donnees.containsKey('dictionnaire')) {
      dictionnaireIngredientsGlobal = Map<String, dynamic>.from(donnees['dictionnaire']).map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    if (donnees.containsKey('bannis')) {
      ingredientsBannisGlobaux = (donnees['bannis'] as List).map((e) => e.toString()).toList();
    }
    if (donnees.containsKey('exclusionsSemaine')) exclusionsSemaineGlobales = (donnees['exclusionsSemaine'] as List).map((e) => e.toString()).toList();
    if (donnees.containsKey('requisSemaine')) requisSemaineGlobaux = (donnees['requisSemaine'] as List).map((e) => e.toString()).toList();
    if (donnees.containsKey('planning')) {
      semaineGlobale = (donnees['planning'] as List).map((e) => Jour.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  } catch (e) {
    debugPrint("🚨 Erreur lecture : $e");
  }
}

Future<void> sauvegarderDonneesLocales() async {
  try {
    // 1. Sauvegarder le thème
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modeSombre', estModeSombreGlobal);

    // 2. Sauvegarder les données
    final fichier = await _obtenirFichierSauvegarde();
    Map<String, dynamic> toutesLesDonnees = {
      'jourDebut': jourDebutGlobal,
      'convivesFoyer': convivesFoyerGlobal,
      'recettes': mesRecettesGlobales,
      'dictionnaire': dictionnaireIngredientsGlobal,
      'bannis': ingredientsBannisGlobaux,
      'exclusionsSemaine': exclusionsSemaineGlobales,
      'requisSemaine': requisSemaineGlobaux,
      'planning': semaineGlobale.map((j) => j.toJson()).toList(),
    };
    await fichier.writeAsString(jsonEncode(toutesLesDonnees));
  } catch (e) {
    debugPrint("🚨 Erreur écriture : $e");
  }
}