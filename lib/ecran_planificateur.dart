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
          if (repas.platSelectionne != null) continue;

          List<Map<String, dynamic>> platsCompatibles = mesRecettesGlobales.where((plat) {
            if (repas.type == "Petit-déjeuner" && plat["categorie"] != "Petit-déjeuner") return false;
            if (repas.type == "Goûter" && plat["categorie"] != "Goûter") return false;
            if ((repas.type == "Midi" || repas.type == "Soir") && (plat["categorie"] == "Petit-déjeuner" || plat["categorie"] == "Goûter")) return false;

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

  Future<void> _exporterPlanningNatifs() async {
    try {
      await sauvegarderDonneesLocales();
      String jsonDeLaSemaine = const JsonEncoder.withIndent('  ').convert(
          semaineGlobale.map((j) => j.toJson()).toList()
      );

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        String? cheminSauvegarde = await FilePicker.platform.saveFile(
          dialogTitle: 'Sauvegarder ton planning',
          fileName: 'mon_menu_semaine.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (cheminSauvegarde != null) {
          File fichier = File(cheminSauvegarde);
          await fichier.writeAsString(jsonDeLaSemaine);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Fichier sauvegardé sur ton PC !"), backgroundColor: Colors.green));
        }
      } else {
        final repertoire = await getTemporaryDirectory();
        final fichier = File('${repertoire.path}/mon_menu_semaine.json');
        await fichier.writeAsString(jsonDeLaSemaine);
        await Share.shareXFiles([XFile(fichier.path)], text: 'Voici mon planning de repas !');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Erreur d'exportation : $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _importerPlanningNatifs() async {
    FilePickerResult? resultat = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (resultat != null && resultat.files.single.path != null) {
      try {
        File fichier = File(resultat.files.single.path!);
        String contenu = await fichier.readAsString();
        List decodePlanning = jsonDecode(contenu);
        setState(() => semaineGlobale = decodePlanning.map((e) => Jour.fromJson(Map<String, dynamic>.from(e))).toList());
        await sauvegarderDonneesLocales();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📥 Menu importé avec succès !"), backgroundColor: Colors.blue));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Ce fichier JSON n'est pas valide."), backgroundColor: Colors.red));
      }
    }
  }

  void _ouvrirConfigurationJour(Jour jour) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setStateBottomSheet) {
          void basculerRepas(String type, bool activer) async {
            setStateBottomSheet(() {
              if (activer) {
                if (!jour.repasDuJour.any((r) => r.type == type)) jour.repasDuJour.add(Repas(type: type, convives: convivesFoyerGlobal));
              } else { jour.repasDuJour.removeWhere((r) => r.type == type); }
            });
            setState(() {});
            await sauvegarderDonneesLocales();
          }
          bool possedeRepas(String type) => jour.repasDuJour.any((r) => r.type == type);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Configuration : ${jour.nomJour}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  const Text("Repas planifiés :", style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(spacing: 8, runSpacing: 8, children: ["Petit-déjeuner", "Midi", "Goûter", "Soir"].map((type) => FilterChip(label: Text(type), selected: possedeRepas(type), selectedColor: Colors.green.shade200, onSelected: (val) => basculerRepas(type, val))).toList()),
                  const Divider(height: 30),
                  const Text("Ingrédients à BANNIR (Ce jour) :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  _construireChampTags("Ex: Tomates...", jour.ingredientsExclus, (val) async { setStateBottomSheet(() => jour.ingredientsExclus.add(val)); setState(() {}); await sauvegarderDonneesLocales(); }, (val) async { setStateBottomSheet(() => jour.ingredientsExclus.remove(val)); setState(() {}); await sauvegarderDonneesLocales(); }),
                  const Divider(height: 30),
                  const Text("Ingrédients OBLIGATOIRES (Ce jour) :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  _construireChampTags("Ex: Poulet...", jour.ingredientsRequis, (val) async { setStateBottomSheet(() => jour.ingredientsRequis.add(val)); setState(() {}); await sauvegarderDonneesLocales(); }, (val) async { setStateBottomSheet(() => jour.ingredientsRequis.remove(val)); setState(() {}); await sauvegarderDonneesLocales(); }),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Valider", style: TextStyle(fontSize: 16)))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _construireChampTags(String hint, List<String> listeTags, Function(String) onAdd, Function(String) onRemove) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(decoration: InputDecoration(hintText: hint, isDense: true, border: const OutlineInputBorder()), onSubmitted: (val) { if (val.trim().isNotEmpty && !listeTags.contains(val.trim())) onAdd(val.trim()); }),
      const SizedBox(height: 8),
      Wrap(
          spacing: 6, runSpacing: 8,
          children: listeTags.map((tag) => InputChip(
              label: Text(tag, style: TextStyle(color: estModeSombreGlobal ? Colors.white : Colors.black)), // CORRECTION COULEUR
              onDeleted: () => onRemove(tag),
              backgroundColor: estModeSombreGlobal ? Colors.grey.shade800 : Colors.grey.shade200 // CORRECTION COULEUR
          )).toList()
      ),
    ]);
  }

  void _choisirPlatManuellement(Repas repas) {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text("Choisir un plat", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView.builder(
                itemCount: mesRecettesGlobales.length,
                itemBuilder: (context, index) {
                  final plat = mesRecettesGlobales[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Color(plat["couleur"]), child: const Icon(Icons.restaurant, color: Colors.white, size: 18)),
                    title: Text(plat["nom"]), subtitle: Text(plat["categorie"]),
                    onTap: () async { setState(() => repas.platSelectionne = plat); await sauvegarderDonneesLocales(); Navigator.pop(context); },
                  );
                },
              ),
            ),
            TextButton(onPressed: () async { setState(() => repas.platSelectionne = null); await sauvegarderDonneesLocales(); Navigator.pop(context); }, child: const Text("Vider ce repas", style: TextStyle(color: Colors.red))),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final joursVisibles = semaineGlobale.where((jour) => jour.estAffiche && jour.repasDuJour.isNotEmpty).toList();

    return Scaffold(
      // CORRECTION : On retire les couleurs "en dur" pour que l'AppBar devienne foncée automatiquement
      appBar: AppBar(
        title: const Text("Planificateur"),
        actions: [
          IconButton(icon: const Icon(Icons.file_download, color: Colors.blue), tooltip: "Importer un planning", onPressed: _importerPlanningNatifs),
          IconButton(icon: const Icon(Icons.save, color: Colors.green), tooltip: "Sauvegarder", onPressed: _exporterPlanningNatifs)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          ExpansionTile(
            title: const Text("Paramètres de la semaine", style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.settings),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Début du planning :"), DropdownButton<String>(value: jourDebutGlobal, items: nomsJours.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(), onChanged: (val) async { setState(() { jourDebutGlobal = val!; _trierSemaineParJourDebut(); }); await sauvegarderDonneesLocales(); })]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Personnes par défaut :"), DropdownButton<int>(value: convivesFoyerGlobal, items: [1, 2, 3, 4, 5, 6].map((v) => DropdownMenuItem(value: v, child: Text("$v pers."))).toList(), onChanged: (val) async { setState(() { convivesFoyerGlobal = val!; for (var j in semaineGlobale) { for (var r in j.repasDuJour) { if (r.platSelectionne == null) r.convives = convivesFoyerGlobal; } } }); await sauvegarderDonneesLocales(); })]),
                    const Divider(),
                    const Text("Jours actifs :", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 10, runSpacing: 8, children: semaineGlobale.map((jour) => FilterChip(label: Text(jour.nomJour.substring(0, 3)), selected: jour.estAffiche, selectedColor: Colors.green.withOpacity(0.3), onSelected: (val) async { setState(() { jour.estAffiche = val; if (val && jour.repasDuJour.isEmpty) { jour.repasDuJour = [Repas(type: "Midi", convives: convivesFoyerGlobal), Repas(type: "Soir", convives: convivesFoyerGlobal)]; } }); await sauvegarderDonneesLocales(); })).toList()),
                    const Divider(height: 30),
                    const Text("BANNIR sur toute la semaine :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 5),
                    _construireChampTags("Ex: Porc, Lait...", exclusionsSemaineGlobales, (val) async { setState(() => exclusionsSemaineGlobales.add(val)); await sauvegarderDonneesLocales(); }, (val) async { setState(() => exclusionsSemaineGlobales.remove(val)); await sauvegarderDonneesLocales(); }),
                    const Divider(height: 30),
                    const Text("IMPOSER sur toute la semaine :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 5),
                    _construireChampTags("Ex: Légumes verts...", requisSemaineGlobaux, (val) async { setState(() => requisSemaineGlobaux.add(val)); await sauvegarderDonneesLocales(); }, (val) async { setState(() => requisSemaineGlobaux.remove(val)); await sauvegarderDonneesLocales(); }),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),

          if (joursVisibles.isEmpty)
            const Padding(padding: EdgeInsets.all(30.0), child: Center(child: Text("Aucun jour planifié.\nActivez des jours dans les paramètres.", textAlign: TextAlign.center))),

          ...joursVisibles.map((jour) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                      // CORRECTION COULEUR BANDEAU DU JOUR
                      decoration: BoxDecoration(
                          color: estModeSombreGlobal ? Colors.grey.shade800 : Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10))
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(jour.nomJour, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), IconButton(icon: const Icon(Icons.settings, size: 20, color: Colors.grey), onPressed: () => _ouvrirConfigurationJour(jour), padding: EdgeInsets.zero, constraints: const BoxConstraints())])
                  ),
                  ...jour.repasDuJour.map((repas) => _construireLigneRepas(repas)).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _remplirAutomatiquement, icon: const Icon(Icons.auto_awesome), label: const Text("Compléter la semaine"), backgroundColor: Colors.green, foregroundColor: Colors.white),
    );
  }

  Widget _construireLigneRepas(Repas repas) {
    bool estVide = repas.platSelectionne == null;
    return InkWell(
      onTap: () => _choisirPlatManuellement(repas),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(repas.type, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(child: estVide ? Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                // CORRECTION COULEUR CASE VIDE
                decoration: BoxDecoration(
                    border: Border.all(
                        color: estModeSombreGlobal ? Colors.grey.shade700 : Colors.grey.shade300,
                        style: BorderStyle.solid
                    ),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: const Text("+ Choisir un plat", style: TextStyle(color: Colors.green)))
                : Row(children: [CircleAvatar(radius: 12, backgroundColor: Color(repas.platSelectionne!["couleur"])), const SizedBox(width: 8), Expanded(child: Text(repas.platSelectionne!["nom"], style: const TextStyle(fontWeight: FontWeight.bold)))])),
          ],
        ),
      ),
    );
  }
}