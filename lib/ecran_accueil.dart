import 'package:flutter/material.dart';
import 'ecran_planificateur.dart'; // Pour lire le menu
import 'donnees_globales.dart';    // Pour le mode sombre

class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {

  String _obtenirNomJourActuel() {
    int jour = DateTime.now().weekday;
    const jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    return jours[jour - 1];
  }

  @override
  Widget build(BuildContext context) {
    String jourActuel = _obtenirNomJourActuel();

    Jour? jourAujourdhui;
    try {
      jourAujourdhui = semaineGlobale.firstWhere((j) => j.nomJour == jourActuel && j.estAffiche);
    } catch (e) {
      jourAujourdhui = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bonjour ! 👋", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // --- LE BOUTON MODE SOMBRE / CLAIR ---
          IconButton(
            icon: Icon(estModeSombreGlobal ? Icons.light_mode : Icons.dark_mode),
            tooltip: "Changer de thème",
            onPressed: () async {
              setState(() {
                estModeSombreGlobal = !estModeSombreGlobal;
                themeNotifier.value = estModeSombreGlobal ? ThemeMode.dark : ThemeMode.light;
              });
              await sauvegarderDonneesLocales();
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Au menu aujourd'hui ($jourActuel) :", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            if (jourAujourdhui == null || jourAujourdhui.repasDuJour.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy, color: Colors.orange, size: 40),
                    const SizedBox(height: 10),
                    const Text("Rien n'est prévu pour aujourd'hui.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Va dans l'onglet Planning pour générer ta semaine.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ],
                ),
              )
            else
              ...jourAujourdhui.repasDuJour.map((repas) {
                bool estVide = repas.platSelectionne == null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: estVide ? Colors.grey.withOpacity(0.3) : Color(repas.platSelectionne!["couleur"]),
                      child: Icon(Icons.restaurant, color: estVide ? Colors.grey : Colors.white),
                    ),
                    title: Text(repas.type, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(
                        estVide ? "Aucun plat prévu" : repas.platSelectionne!["nom"],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: estVide ? Colors.grey : null)
                    ),
                  ),
                );
              }).toList(),

            const Spacer(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}