import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- CLASSES POUR LE PLANNING ---
class Repas {
  String type;
  int convives;

  // Le plat principal (Classique)
  Map<String, dynamic>? platSelectionne;

  // Les nouveautés pour le repas complet / décomposé
  bool estDecompose;
  String? proteine;
  String? legume;
  String? feculent;

  Map<String, dynamic>? entree;
  Map<String, dynamic>? dessert;

  Repas({
    required this.type,
    required this.convives,
    this.platSelectionne,
    this.estDecompose = false,
    this.proteine,
    this.legume,
    this.feculent,
    this.entree,
    this.dessert,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'convives': convives,
    'platSelectionne': platSelectionne,
    'estDecompose': estDecompose,
    'proteine': proteine,
    'legume': legume,
    'feculent': feculent,
    'entree': entree,
    'dessert': dessert,
  };

  factory Repas.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsePlat(dynamic data) {
      if (data == null) return null;
      try {
        var plat = Map<String, dynamic>.from(data);
        if (plat['ingredients'] != null) {
          plat['ingredients'] = (plat['ingredients'] as List).map((e) => e.toString()).toList();
        }
        return plat;
      } catch (e) {
        return null;
      }
    }

    return Repas(
      type: json['type']?.toString() ?? "Midi",
      convives: int.tryParse(json['convives']?.toString() ?? '2') ?? 2,
      platSelectionne: parsePlat(json['platSelectionne']),
      estDecompose: json['estDecompose'] ?? false,
      proteine: json['proteine']?.toString(),
      legume: json['legume']?.toString(),
      feculent: json['feculent']?.toString(),
      entree: parsePlat(json['entree']),
      dessert: parsePlat(json['dessert']),
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

// --- VARIABLES GLOBALES ---
List<Map<String, dynamic>> mesRecettesGlobales = [
  {"nom": "Poulet rôti & Légumes", "rapide": false, "tempsExact": 45, "categorie": "Plat principal", "couleur": Colors.orange.value, "legumes": 50, "proteines": 50, "feculents": 0, "ingredients": ["Poulet", "Carottes", "Oignons"]},
  {"nom": "Pâtes au Pesto", "rapide": true, "tempsExact": 15, "categorie": "Plat principal", "couleur": Colors.green.value, "legumes": 10, "proteines": 10, "feculents": 80, "ingredients": ["Pâtes", "Pesto", "Parmesan"]},
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

bool estModeSombreGlobal = false;
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// --- GESTION DU FICHIER ---
Future<File> _obtenirFichierSauvegarde() async {
  final repertoire = await getApplicationDocumentsDirectory();
  return File('${repertoire.path}/mes_donnees_repas.json');
}

Future<void> chargerDonneesLocales() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    estModeSombreGlobal = prefs.getBool('modeSombre') ?? false;
    themeNotifier.value = estModeSombreGlobal ? ThemeMode.dark : ThemeMode.light;

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
        if (plat['legumes'] != null) plat['legumes'] = (plat['legumes'] as num).toInt();
        if (plat['proteines'] != null) plat['proteines'] = (plat['proteines'] as num).toInt();
        if (plat['feculents'] != null) plat['feculents'] = (plat['feculents'] as num).toInt();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('modeSombre', estModeSombreGlobal);

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