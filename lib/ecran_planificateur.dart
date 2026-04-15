import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'donnees_globales.dart';
export 'donnees_globales.dart';

class EcranPlanificateur extends StatefulWidget {
  const EcranPlanificateur({super.key});
  @override
  State<EcranPlanificateur> createState() => _EcranPlanificateurState();
}

class _EcranPlanificateurState extends State<EcranPlanificateur> {
  final List<String> nomsJours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];

  @override
  void initState() {
    super.initState();
    if (semaineGlobale.isEmpty) {
      _initialiserSemaine();
    }
  }

  void _initialiserSemaine() {
    semaineGlobale = nomsJours.map((nom) {
      return Jour(nomJour: nom, repasDuJour: [Repas(type: "Midi", convives: convivesFoyerGlobal), Repas(type: "Soir", convives: convivesFoyerGlobal)]);
    }).toList();
    _trierSemaineParJourDebut();
  }

  void _trierSemaineParJourDebut() {
    int indexDepart = nomsJours.indexOf(jourDebutGlobal);
    List<String> ordreJours = [];
    for (int i = 0; i < 7; i++) { ordreJours.add(nomsJours[(indexDepart + i) % 7]); }
    semaineGlobale.sort((a, b) => ordreJours.indexOf(a.nomJour).compareTo(ordreJours.indexOf(b.nomJour)));
  }

  Future<void> _remplirAutomatiquement() async {
    final random = Random();
    setState(() {
      for (var jour in semaineGlobale) {
        if (!jour.estAffiche || jour.repasDuJour.isEmpty) continue;
        for (var repas in jour.repasDuJour) {
          // On ne remplit automatiquement que s'il n'y a pas de plat principal ET que ce n'est pas décomposé
          if (repas.platSelectionne != null || repas.estDecompose) continue;

          List<Map<String, dynamic>> platsCompatibles = mesRecettesGlobales.where((plat) {
            if (repas.type == "Petit-déjeuner" && plat["categorie"] != "Petit-déjeuner") return false;
            if (repas.type == "Goûter" && plat["categorie"] != "Goûter") return false;
            if ((repas.type == "Midi" || repas.type == "Soir") && (plat["categorie"] == "Petit-déjeuner" || plat["categorie"] == "Goûter" || plat["categorie"] == "Entrée" || plat["categorie"] == "Dessert")) return false;

            List<String> ingredientsPlat = List<String>.from(plat["ingredients"]).map((e) => e.toLowerCase()).toList();

            for (String exclu in exclusionsSemaineGlobales) { if (ingredientsPlat.contains(exclu.toLowerCase())) return false; }
            for (String exclu in jour.ingredientsExclus) { if (ingredientsPlat.contains(exclu.toLowerCase())) return false; }
            for (String requis in requisSemaineGlobaux) { if (!ingredientsPlat.contains(requis.toLowerCase())) return false; }
            for (String requis in jour.ingredientsRequis) { if (!ingredientsPlat.contains(requis.toLowerCase())) return false; }
            return true;
          }).toList();

          if (platsCompatibles.isNotEmpty) repas.platSelectionne = platsCompatibles[random.nextInt(platsCompatibles.length)];
        }
      }
    });
    await sauvegarderDonneesLocales();
  }

  Future<void> _viderSemaine() async {
    bool? confirmer = await showDialog<bool>(context: context, builder: (context) {
      return AlertDialog(title: const Text("Vider la semaine ?"), content: const Text("Effacer tous les plats ?"), actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text("Tout effacer")),
      ]);
    });

    if (confirmer == true) {
      setState(() {
        for (var jour in semaineGlobale) {
          for (var repas in jour.repasDuJour) {
            repas.platSelectionne = null;
            repas.estDecompose = false;
            repas.proteine = null; repas.legume = null; repas.feculent = null;
            repas.entree = null; repas.dessert = null;
          }
        }
      });
      await sauvegarderDonneesLocales();
    }
  }

  // ... (Je conserve _exporterPlanningNatifs et _importerPlanningNatifs identiques pour ne pas alourdir, garde tes fonctions existantes ici)
  Future<void> _exporterPlanningNatifs() async {
    try {
      await sauvegarderDonneesLocales();
      String jsonDeLaSemaine = const JsonEncoder.withIndent('  ').convert(semaineGlobale.map((j) => j.toJson()).toList());
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        String? cheminSauvegarde = await FilePicker.platform.saveFile(dialogTitle: 'Sauvegarder ton planning', fileName: 'mon_menu_semaine.json', type: FileType.custom, allowedExtensions: ['json']);
        if (cheminSauvegarde != null) { File(cheminSauvegarde).writeAsStringSync(jsonDeLaSemaine); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Sauvegardé !"), backgroundColor: Colors.green)); }
      } else {
        final repertoire = await getTemporaryDirectory();
        final fichier = File('${repertoire.path}/mon_menu_semaine.json');
        await fichier.writeAsString(jsonDeLaSemaine);
        await Share.shareXFiles([XFile(fichier.path)], text: 'Voici mon planning !');
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Erreur : $e"), backgroundColor: Colors.red)); }
  }

  Future<void> _importerPlanningNatifs() async {
    FilePickerResult? resultat = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (resultat != null && resultat.files.single.path != null) {
      try {
        String contenu = await File(resultat.files.single.path!).readAsString();
        var decodePlanning = jsonDecode(contenu);
        if (decodePlanning is! List || (decodePlanning.isNotEmpty && !(decodePlanning[0] as Map).containsKey('nomJour'))) throw Exception("Ce n'est pas un planning !");

        setState(() { semaineGlobale = decodePlanning.map((e) => Jour.fromJson(Map<String, dynamic>.from(e))).toList(); });
        await sauvegarderDonneesLocales();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📥 Menu importé !"), backgroundColor: Colors.blue));
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Fichier invalide."), backgroundColor: Colors.red)); }
    }
  }

  // --- NOUVEAU MENU DE CONFIGURATION COMPLET D'UN REPAS ---
  void _ouvrirConfigurationRepas(Repas repas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          void choisirRecette(String categorie, Function(Map<String, dynamic>?) onSelect) {
            showDialog(context: context, builder: (context) {
              var recettesFiltrees = mesRecettesGlobales.where((r) => r["categorie"] == categorie).toList();
              return AlertDialog(
                title: Text("Choisir : $categorie"),
                content: SizedBox(
                  width: double.maxFinite, height: 300,
                  child: ListView.builder(
                      itemCount: recettesFiltrees.length,
                      itemBuilder: (context, index) {
                        var plat = recettesFiltrees[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Color(plat["couleur"]), radius: 15),
                          title: Text(plat["nom"]),
                          onTap: () { onSelect(plat); Navigator.pop(context); },
                        );
                      }
                  ),
                ),
                actions: [
                  TextButton(onPressed: () { onSelect(null); Navigator.pop(context); }, child: const Text("Retirer", style: TextStyle(color: Colors.red))),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
                ],
              );
            });
          }

          Widget ligneDecomposee(String label, String? valeur, Function(String) onChanged) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: TextFormField(
                      initialValue: valeur,
                      decoration: InputDecoration(hintText: "Ex: Poulet...", isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Configurer le ${repas.type.toLowerCase()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18), label: const Text("Vider", style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          setState(() { repas.entree = null; repas.platSelectionne = null; repas.estDecompose = false; repas.proteine = null; repas.legume = null; repas.feculent = null; repas.dessert = null; });
                          await sauvegarderDonneesLocales(); Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                  const Divider(),

                  // ENTREE
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("🥗 Entrée", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(repas.entree?["nom"] ?? "Aucune entrée", style: TextStyle(color: repas.entree == null ? Colors.grey : Colors.green)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => choisirRecette("Entrée", (plat) async { setStateModal(() => repas.entree = plat); setState((){}); await sauvegarderDonneesLocales(); }),
                  ),
                  const Divider(),

                  // PLAT PRINCIPAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🥘 Plat Principal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          const Text("Décomposé", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Switch(
                              value: repas.estDecompose,
                              onChanged: (val) async { setStateModal(() { repas.estDecompose = val; if(val) repas.platSelectionne = null; }); setState((){}); await sauvegarderDonneesLocales(); }
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (!repas.estDecompose)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                      tileColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      leading: repas.platSelectionne != null ? CircleAvatar(backgroundColor: Color(repas.platSelectionne!["couleur"])) : const Icon(Icons.restaurant, color: Colors.grey),
                      title: Text(repas.platSelectionne?["nom"] ?? "Choisir un plat complet..."),
                      onTap: () => choisirRecette("Plat principal", (plat) async { setStateModal(() => repas.platSelectionne = plat); setState((){}); await sauvegarderDonneesLocales(); }),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.orange.shade300), borderRadius: BorderRadius.circular(8), color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50),
                      child: Column(
                        children: [
                          ligneDecomposee("Protéine", repas.proteine, (val) { repas.proteine = val.isEmpty ? null : val; sauvegarderDonneesLocales(); }),
                          ligneDecomposee("Légume", repas.legume, (val) { repas.legume = val.isEmpty ? null : val; sauvegarderDonneesLocales(); }),
                          ligneDecomposee("Féculent", repas.feculent, (val) { repas.feculent = val.isEmpty ? null : val; sauvegarderDonneesLocales(); }),
                        ],
                      ),
                    ),

                  const Divider(),

                  // DESSERT
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("🍰 Dessert", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(repas.dessert?["nom"] ?? "Aucun dessert", style: TextStyle(color: repas.dessert == null ? Colors.grey : Colors.green)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => choisirRecette("Dessert", (plat) async { setStateModal(() => repas.dessert = plat); setState((){}); await sauvegarderDonneesLocales(); }),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () { setState((){}); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Terminer", style: TextStyle(color: Colors.white, fontSize: 16)))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _modifierConvivesRepas(Repas repas) async {
    int tempConvives = repas.convives;
    await showDialog(context: context, builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text("Convives pour le ${repas.type.toLowerCase()}"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 35), onPressed: tempConvives > 1 ? () => setStateDialog(() => tempConvives--) : null),
              const SizedBox(width: 20), Text("$tempConvives", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)), const SizedBox(width: 20),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 35), onPressed: () => setStateDialog(() => tempConvives++)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () { setState(() { repas.convives = tempConvives; }); sauvegarderDonneesLocales(); Navigator.pop(context); }, child: const Text("Valider"))
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... [Garde le Scaffold exactement identique jusqu'à _construireLigneRepas]
    final joursVisibles = semaineGlobale.where((jour) => jour.estAffiche && jour.repasDuJour.isNotEmpty).toList();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Planificateur"), actions: [
        IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), tooltip: "Vider la semaine", onPressed: _viderSemaine),
        IconButton(icon: const Icon(Icons.file_download, color: Colors.blue), tooltip: "Importer un planning", onPressed: _importerPlanningNatifs),
        IconButton(icon: const Icon(Icons.save, color: Colors.green), tooltip: "Sauvegarder", onPressed: _exporterPlanningNatifs)
      ]),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // (Garde ton bloc ExpansionTile des paramètres ici, il ne change pas)

          if (joursVisibles.isEmpty) const Padding(padding: EdgeInsets.all(30.0), child: Center(child: Text("Aucun jour planifié.", textAlign: TextAlign.center))),

          ...joursVisibles.map((jour) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                      decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                      child: Text(jour.nomJour, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black))
                  ),
                  ...jour.repasDuJour.map((repas) => _construireLigneRepas(repas, isDark)).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _remplirAutomatiquement, icon: const Icon(Icons.auto_awesome), label: const Text("Compléter"), backgroundColor: Colors.green, foregroundColor: Colors.white),
    );
  }

  Widget _construireLigneRepas(Repas repas, bool isDark) {
    bool estTotalementVide = repas.platSelectionne == null && !repas.estDecompose && repas.entree == null && repas.dessert == null;

    // Construction du texte de résumé
    String textePrincipal = "";
    if (repas.estDecompose) {
      List<String> parts = [];
      if (repas.proteine != null) parts.add(repas.proteine!);
      if (repas.legume != null) parts.add(repas.legume!);
      if (repas.feculent != null) parts.add(repas.feculent!);
      textePrincipal = parts.isEmpty ? "À composer..." : parts.join(" • ");
    } else if (repas.platSelectionne != null) {
      textePrincipal = repas.platSelectionne!["nom"];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(repas.type.substring(0, 4), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),

          Expanded(
            child: InkWell(
              onTap: () => _ouvrirConfigurationRepas(repas),
              borderRadius: BorderRadius.circular(8),
              child: estTotalementVide
                  ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                  child: const Text("+ Configurer", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
              )
                  : Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (repas.entree != null) Text("🥗 ${repas.entree!['nom']}", style: const TextStyle(fontSize: 11, color: Colors.green)),
                      if (textePrincipal.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(textePrincipal, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      if (repas.dessert != null) Text("🍰 ${repas.dessert!['nom']}", style: const TextStyle(fontSize: 11, color: Colors.orange)),
                    ],
                  )
              ),
            ),
          ),

          const SizedBox(width: 8),
          InkWell(
            onTap: () => _modifierConvivesRepas(repas),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [const Icon(Icons.people, size: 16, color: Colors.grey), const SizedBox(width: 4), Text("${repas.convives}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))]),
            ),
          ),
        ],
      ),
    );
  }
}