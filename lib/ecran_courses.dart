import 'package:flutter/material.dart';
import 'ecran_planificateur.dart';
import 'donnees_globales.dart';

class EcranCourses extends StatefulWidget {
  const EcranCourses({super.key});
  @override
  State<EcranCourses> createState() => _EcranCoursesState();
}

class _EcranCoursesState extends State<EcranCourses> {
  List<String> ingredientsCoches = [];

  Map<String, int> _calculerCoursesTotales() {
    Map<String, int> courses = {};
    for (var jour in semaineGlobale) {
      if (!jour.estAffiche) continue;
      for (var repas in jour.repasDuJour) {
        if (repas.platSelectionne != null) {
          for (String ingredient in repas.platSelectionne!["ingredients"]) {
            courses[ingredient] = (courses[ingredient] ?? 0) + repas.convives;
          }
        }
      }
    }
    return courses;
  }

  @override
  Widget build(BuildContext context) {
    final coursesTotales = _calculerCoursesTotales();
    Map<String, Map<String, int>> aAcheterParCategorie = {};
    Map<String, int> dejaCoches = {};

    coursesTotales.forEach((ingredient, portions) {
      if (ingredientsCoches.contains(ingredient)) {
        dejaCoches[ingredient] = portions;
      } else {
        String categorie = dictionnaireIngredientsGlobal[ingredient] ?? "📦 Autres";
        if (!aAcheterParCategorie.containsKey(categorie)) aAcheterParCategorie[categorie] = {};
        aAcheterParCategorie[categorie]![ingredient] = portions;
      }
    });

    List<String> categoriesTriees = aAcheterParCategorie.keys.toList()..sort();
    List<String> clesCochees = dejaCoches.keys.toList()..sort();

    return Scaffold(
      // CORRECTION : On retire les couleurs "en dur" de la barre
      appBar: AppBar(
        title: const Text("Liste de Courses"),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: () => setState(() => ingredientsCoches.clear()), tooltip: "Vider le caddie")
        ],
      ),
      body: coursesTotales.isEmpty
          ? const Center(child: Text("Ton menu est vide.\nVa générer ta semaine d'abord !", textAlign: TextAlign.center))
          : ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          ...categoriesTriees.map((categorie) {
            final itemsDeCeRayon = aAcheterParCategorie[categorie]!;
            final clesItems = itemsDeCeRayon.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // CORRECTION COULEUR CATEGORIE
                  color: estModeSombreGlobal ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Text(categorie, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...clesItems.map((ingredient) {
                  return CheckboxListTile(
                    title: Text(ingredient, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${itemsDeCeRayon[ingredient]} portion(s)"),
                    value: false, activeColor: Colors.green,
                    onChanged: (val) { setState(() { ingredientsCoches.add(ingredient); }); },
                  );
                }),
              ],
            );
          }),

          if (dejaCoches.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // CORRECTION COULEUR "DANS LE CADDIE" (Vert transparent au lieu de fluo)
              color: estModeSombreGlobal ? Colors.green.withOpacity(0.2) : Colors.green.shade100,
              child: const Text("✅ Dans le caddie", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            ),
            ...clesCochees.map((ingredient) {
              return CheckboxListTile(
                title: Text(ingredient, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontWeight: FontWeight.bold)),
                subtitle: Text("${dejaCoches[ingredient]} portion(s)", style: const TextStyle(color: Colors.grey)),
                value: true, activeColor: Colors.grey,
                onChanged: (val) { setState(() { ingredientsCoches.remove(ingredient); }); },
              );
            }),
          ],
        ],
      ),
    );
  }
}