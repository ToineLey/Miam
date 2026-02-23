import 'package:flutter/material.dart';

// --- 1. LES VARIABLES GLOBALES DE L'APPLICATION ---

// La liste de tes recettes
List<Map<String, dynamic>> mesRecettesGlobales = [
  {"nom": "Poulet rôti & Légumes", "rapide": false, "tempsExact": 45, "categorie": "Plat principal", "couleur": Colors.orange.value, "legumes": 50.0, "proteines": 50.0, "feculents": 0.0, "ingredients": ["Poulet", "Carottes", "Oignons"]},
  {"nom": "Pâtes au Pesto", "rapide": true, "tempsExact": 15, "categorie": "Plat principal", "couleur": Colors.green.value, "legumes": 10.0, "proteines": 10.0, "feculents": 80.0, "ingredients": ["Pâtes", "Pesto", "Parmesan"]},
  {"nom": "Pancakes Protéinés", "rapide": true, "tempsExact": 10, "categorie": "Petit-déjeuner", "couleur": Colors.brown.value, "legumes": 0.0, "proteines": 60.0, "feculents": 40.0, "ingredients": ["Oeufs", "Flocons d'avoine", "Lait"]},
];

// Les catégories (rayons) disponibles
final List<String> rayonsSupermarche = [
  "🥦 Fruits & Légumes", "🥩 Viandes & Poissons", "🧀 Frais & Laitier",
  "🍝 Épicerie Salée", "🍯 Épicerie Sucrée", "🥖 Boulangerie",
  "🌱 Rayon Végétarien", "📦 Autres"
];

// Le dictionnaire qui associe chaque ingrédient à son rayon
Map<String, String> dictionnaireIngredientsGlobal = {
  "Poulet": "🥩 Viandes & Poissons", "Boeuf": "🥩 Viandes & Poissons", "Saumon": "🥩 Viandes & Poissons",
  "Oeufs": "🧀 Frais & Laitier", "Lait": "🧀 Frais & Laitier", "Beurre": "🧀 Frais & Laitier", "Parmesan": "🧀 Frais & Laitier",
  "Carottes": "🥦 Fruits & Légumes", "Oignons": "🥦 Fruits & Légumes", "Tomates": "🥦 Fruits & Légumes", "Salade": "🥦 Fruits & Légumes",
  "Pâtes": "🍝 Épicerie Salée", "Riz": "🍝 Épicerie Salée", "Huile d'olive": "🍝 Épicerie Salée", "Pesto": "🍝 Épicerie Salée",
  "Farine": "🍯 Épicerie Sucrée", "Flocons d'avoine": "🍯 Épicerie Sucrée",
  "Croûtons": "🥖 Boulangerie",
};


// --- 2. L'ÉCRAN DE LA BIBLIOTHÈQUE ---
class EcranBibliotheque extends StatefulWidget {
  const EcranBibliotheque({super.key});
  @override
  State<EcranBibliotheque> createState() => _EcranBibliothequeState();
}

class _EcranBibliothequeState extends State<EcranBibliotheque> {
  String rechercheText = "";
  String triActuel = "Nom (A-Z)";
  String filtreCategorie = "Toutes";

  final List<String> optionsTri = ["Nom (A-Z)", "Temps (Court)", "+ de Légumes", "+ de Protéines", "+ de Féculents"];
  final List<String> toutesCategories = ["Toutes", "Petit-déjeuner", "Entrée", "Plat principal", "Goûter", "Dessert"];

  List<Map<String, dynamic>> get platsFiltres {
    List<Map<String, dynamic>> liste = mesRecettesGlobales.where((plat) {
      bool correspondRecherche = plat["nom"].toString().toLowerCase().contains(rechercheText.toLowerCase()) ||
          (plat["ingredients"] as List).any((ing) => ing.toString().toLowerCase().contains(rechercheText.toLowerCase()));
      bool correspondCategorie = filtreCategorie == "Toutes" || plat["categorie"] == filtreCategorie;
      return correspondRecherche && correspondCategorie;
    }).toList();

    liste.sort((a, b) {
      int tempsA = a["rapide"] ? (a["tempsExact"] ?? 15) : (a["tempsExact"] ?? 999);
      int tempsB = b["rapide"] ? (b["tempsExact"] ?? 15) : (b["tempsExact"] ?? 999);
      switch (triActuel) {
        case "Temps (Court)": return tempsA.compareTo(tempsB);
        case "+ de Légumes": return (b["legumes"] as double).compareTo(a["legumes"] as double);
        case "+ de Protéines": return (b["proteines"] as double).compareTo(a["proteines"] as double);
        case "+ de Féculents": return (b["feculents"] as double).compareTo(a["feculents"] as double);
        case "Nom (A-Z)": default: return a["nom"].toString().compareTo(b["nom"].toString());
      }
    });
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carnet de Recettes"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(decoration: InputDecoration(hintText: "Chercher un plat...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(vertical: 0)), onChanged: (val) => setState(() => rechercheText = val)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: "Catégorie", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)), value: filtreCategorie, items: toutesCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (val) => setState(() => filtreCategorie = val!))),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(isExpanded: true, decoration: const InputDecoration(labelText: "Trier par", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)), value: triActuel, items: optionsTri.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (val) => setState(() => triActuel = val!))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: platsFiltres.isEmpty
                ? const Center(child: Text("Aucun plat trouvé."))
                : ListView.builder(
              itemCount: platsFiltres.length,
              itemBuilder: (context, index) {
                final plat = platsFiltres[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Color(plat["couleur"]), child: const Icon(Icons.restaurant_menu, color: Colors.white)),
                    title: Text(plat["nom"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${plat["categorie"]} • ${plat["rapide"] ? '< 20' : plat['tempsExact']} min"),
                        Wrap(spacing: 4, children: (plat["ingredients"] as List).map((ing) => Chip(label: Text(ing, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList())
                      ],
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () => _afficherFormulaireCreation(context, platAEditer: plat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _afficherFormulaireCreation(context), icon: const Icon(Icons.add), label: const Text("Créer un plat"), backgroundColor: Colors.green),
    );
  }

  void _afficherFormulaireCreation(BuildContext context, {Map<String, dynamic>? platAEditer}) async {
    final nouvelleRecette = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) { return FormulaireCreationPlat(platAEditer: platAEditer); },
    );

    if (nouvelleRecette != null) {
      setState(() {
        if (platAEditer != null) {
          int index = mesRecettesGlobales.indexOf(platAEditer);
          if (index != -1) mesRecettesGlobales[index] = nouvelleRecette;
        } else {
          mesRecettesGlobales.add(nouvelleRecette);
        }
      });
    }
  }
}

// --- 3. LE FORMULAIRE DE CRÉATION DE PLAT ---
class FormulaireCreationPlat extends StatefulWidget {
  final Map<String, dynamic>? platAEditer;
  const FormulaireCreationPlat({super.key, this.platAEditer});
  @override
  State<FormulaireCreationPlat> createState() => _FormulaireCreationPlatState();
}

class _FormulaireCreationPlatState extends State<FormulaireCreationPlat> {
  late TextEditingController _nomController;
  late TextEditingController _tempsController;
  late TextEditingController _ingredientController;

  bool estRapide = false;
  double legumes = 34; double proteines = 33; double feculents = 33;
  String categorieSelectionnee = "Plat principal";
  Color couleurSelectionnee = Colors.blue;

  List<String> ingredientsSelectionnes = [];
  List<String> suggestions = [];

  final List<String> categoriesPossibles = ["Petit-déjeuner", "Entrée", "Plat principal", "Goûter", "Dessert"];
  final List<Color> couleursPossibles = [Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue, Colors.cyan, Colors.teal, Colors.green, Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange, Colors.brown, Colors.grey, Colors.blueGrey];

  @override
  void initState() {
    super.initState();
    final plat = widget.platAEditer;
    _nomController = TextEditingController(text: plat?["nom"] ?? "");
    estRapide = plat?["rapide"] ?? false;
    _tempsController = TextEditingController(text: plat != null && plat["tempsExact"] != null ? plat["tempsExact"].toString() : "");
    _ingredientController = TextEditingController();

    if (plat != null) {
      legumes = plat["legumes"]; proteines = plat["proteines"]; feculents = plat["feculents"];
      categorieSelectionnee = plat["categorie"]; couleurSelectionnee = Color(plat["couleur"]);
      ingredientsSelectionnes = List<String>.from(plat["ingredients"]);
    }
    _mettreAJourSuggestions("");
  }

  @override
  void dispose() { _nomController.dispose(); _tempsController.dispose(); _ingredientController.dispose(); super.dispose(); }

  double get total => legumes + proteines + feculents;

  void _mettreAJourSuggestions(String texte) {
    setState(() {
      suggestions = dictionnaireIngredientsGlobal.keys.where((ing) => ing.toLowerCase().contains(texte.toLowerCase())).where((ing) => !ingredientsSelectionnes.contains(ing)).toList();
    });
  }

  // LA MÉTHODE INTELLIGENTE D'AJOUT D'INGRÉDIENT
  void _ajouterIngredient(String valeur) {
    String ing = valeur.trim();
    if (ing.isEmpty || ingredientsSelectionnes.contains(ing)) return;

    if (dictionnaireIngredientsGlobal.containsKey(ing)) {
      // S'il existe déjà dans le dictionnaire global, on l'ajoute directement
      setState(() {
        ingredientsSelectionnes.add(ing);
        _ingredientController.clear();
        _mettreAJourSuggestions("");
      });
    } else {
      // S'il est inconnu, on ouvre la popup pour demander sa catégorie
      _demanderCategoriePourNouvelIngredient(ing);
    }
  }

  // LA FENÊTRE POUR CLASSER UN NOUVEL INGRÉDIENT
  Future<void> _demanderCategoriePourNouvelIngredient(String ingredientNom) async {
    String categorieChoisie = rayonsSupermarche.first;

    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Nouveau : $ingredientNom"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Dans quel rayon se trouve cet ingrédient ?"),
                const SizedBox(height: 10),
                StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return DropdownButton<String>(
                        isExpanded: true,
                        value: categorieChoisie,
                        items: rayonsSupermarche.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) => setStateDialog(() => categorieChoisie = val!),
                      );
                    }
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    // On l'enregistre dans le dictionnaire global
                    dictionnaireIngredientsGlobal[ingredientNom] = categorieChoisie;

                    // On l'ajoute à la recette en cours
                    setState(() {
                      ingredientsSelectionnes.add(ingredientNom);
                      _ingredientController.clear();
                      _mettreAJourSuggestions("");
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Enregistrer")
              )
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final estModeEdition = widget.platAEditer != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(estModeEdition ? "Modifier la recette" : "Nouvelle Recette Perso", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: couleursPossibles.length, itemBuilder: (context, index) {
                final couleur = couleursPossibles[index];
                return GestureDetector(onTap: () => setState(() => couleurSelectionnee = couleur), child: Container(margin: const EdgeInsets.only(right: 10), width: 40, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle, border: couleurSelectionnee == couleur ? Border.all(color: Colors.black, width: 3) : null)));
              })),
              const SizedBox(height: 15),

              Row(children: [
                Expanded(flex: 2, child: TextField(controller: _nomController, decoration: const InputDecoration(labelText: "Nom du plat", border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: DropdownButtonFormField<String>(isExpanded: true, value: categorieSelectionnee, decoration: const InputDecoration(labelText: "Type", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)), items: categoriesPossibles.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (val) => setState(() => categorieSelectionnee = val!))),
              ]),
              const SizedBox(height: 15),

              TextField(controller: _ingredientController, decoration: InputDecoration(labelText: "Rechercher ou ajouter un ingrédient...", border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _ajouterIngredient(_ingredientController.text))), onChanged: _mettreAJourSuggestions, onSubmitted: _ajouterIngredient),
              const SizedBox(height: 10),
              if (suggestions.isNotEmpty) Wrap(spacing: 6, runSpacing: -8, children: suggestions.take(12).map((ing) => ActionChip(label: Text(ing, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.grey.shade200, onPressed: () => _ajouterIngredient(ing))).toList()),
              const SizedBox(height: 15),
              if (ingredientsSelectionnes.isNotEmpty) const Text("Dans cette recette :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
              Wrap(spacing: 8, children: ingredientsSelectionnes.map((ing) => InputChip(label: Text(ing, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green, deleteIconColor: Colors.white, onDeleted: () { setState(() { ingredientsSelectionnes.remove(ing); _mettreAJourSuggestions(_ingredientController.text); }); })).toList()),
              const SizedBox(height: 10),

              SwitchListTile(title: const Text("Recette rapide (< 20 min)"), value: estRapide, onChanged: (val) => setState(() { estRapide = val; if (val) _tempsController.clear(); }), contentPadding: EdgeInsets.zero),
              if (!estRapide) ...[const SizedBox(height: 10), TextField(controller: _tempsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Temps exact (min)", border: OutlineInputBorder()))],
              const Divider(height: 30),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Répartition :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(total == 100 ? "Complet (100%)" : "Reste à allouer : ${(100 - total).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: total == 100 ? Colors.green : Colors.orange)),
              ]),
              const SizedBox(height: 10),

              _construireSlider("Légumes", legumes, Colors.green, (val) => setState(() => legumes = val > (100 - proteines - feculents) ? (100 - proteines - feculents) : val)),
              _construireSlider("Protéines", proteines, Colors.redAccent, (val) => setState(() => proteines = val > (100 - legumes - feculents) ? (100 - legumes - feculents) : val)),
              _construireSlider("Féculents", feculents, Colors.orange, (val) => setState(() => feculents = val > (100 - legumes - proteines) ? (100 - legumes - proteines) : val)),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: total == 100 ? () {
                    Map<String, dynamic> nouvelleRecette = {
                      "nom": _nomController.text.trim().isEmpty ? "Nouvelle Recette" : _nomController.text.trim(),
                      "rapide": estRapide,
                      "tempsExact": estRapide ? 15 : (int.tryParse(_tempsController.text) ?? 30),
                      "categorie": categorieSelectionnee,
                      "couleur": couleurSelectionnee.value,
                      "legumes": legumes,
                      "proteines": proteines,
                      "feculents": feculents,
                      "ingredients": ingredientsSelectionnes,
                    };
                    Navigator.pop(context, nouvelleRecette);
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(estModeEdition ? "Sauvegarder" : "Ajouter à la bibliothèque", style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireSlider(String label, double valeur, Color couleur, Function(double) onChanged) {
    return Row(children: [SizedBox(width: 80, child: Text(label)), Expanded(child: Slider(value: valeur, min: 0, max: 100, activeColor: couleur, onChanged: onChanged)), SizedBox(width: 40, child: Text("${valeur.toInt()}%", textAlign: TextAlign.right))]);
  }
}