import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'donnees_globales.dart';

class EcranSwipe extends StatefulWidget {
  const EcranSwipe({super.key});

  @override
  State<EcranSwipe> createState() => _EcranSwipeState();
}

class _EcranSwipeState extends State<EcranSwipe> {
  int modeActuel = 0;

  final CardSwiperController _swiperControllerRecettes = CardSwiperController();
  final CardSwiperController _swiperControllerIngredients = CardSwiperController();

  final List<Map<String, dynamic>> baseDecouverteInternet = [
    {"nom": "Curry de Pois Chiches", "rapide": true, "tempsExact": 20, "categorie": "Plat principal", "couleur": Colors.orange.value, "legumes": 40, "proteines": 30, "feculents": 30, "ingredients": ["Pois chiches", "Lait de coco", "Curry", "Riz"]},
    {"nom": "Soupe à l'Oignon", "rapide": false, "tempsExact": 45, "categorie": "Entrée", "couleur": Colors.amber.value, "legumes": 80, "proteines": 0, "feculents": 20, "ingredients": ["Oignons", "Bouillon", "Pain", "Emmental"]},
    {"nom": "Wok de Crevettes", "rapide": true, "tempsExact": 15, "categorie": "Plat principal", "couleur": Colors.pink.value, "legumes": 50, "proteines": 30, "feculents": 20, "ingredients": ["Crevettes", "Poivrons", "Sauce Soja", "Nouilles"]},
    {"nom": "Gratin Dauphinois", "rapide": false, "tempsExact": 60, "categorie": "Plat principal", "couleur": Colors.yellow.value, "legumes": 0, "proteines": 20, "feculents": 80, "ingredients": ["Pommes de terre", "Crème", "Lait", "Ail"]},
    {"nom": "Mousse au Chocolat", "rapide": true, "tempsExact": 15, "categorie": "Dessert", "couleur": Colors.brown.value, "legumes": 0, "proteines": 30, "feculents": 70, "ingredients": ["Chocolat", "Oeufs", "Sucre"]},
  ];

  final List<String> ingredientsANoter = [
    "Oignons", "Ail", "Coriandre", "Lait de coco", "Crevettes", "Champignons", "Poivrons", "Fromage de chèvre"
  ];

  List<Map<String, dynamic>> get recettesAffichees {
    return baseDecouverteInternet.where((plat) {
      List<String> ingredientsDuPlat = List<String>.from(plat["ingredients"]).map((e) => e.toLowerCase()).toList();
      for (String banni in ingredientsBannisGlobaux) {
        if (ingredientsDuPlat.contains(banni.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text("Découvrir des plats"), icon: Icon(Icons.restaurant)),
                  ButtonSegment(value: 1, label: Text("Mes goûts"), icon: Icon(Icons.favorite)),
                ],
                selected: {modeActuel},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() => modeActuel = newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) return estModeSombreGlobal ? Colors.green.withOpacity(0.3) : Colors.green.shade100;
                    return estModeSombreGlobal ? Colors.grey.shade900 : Colors.white;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    return estModeSombreGlobal ? Colors.white : Colors.black;
                  }),
                ),
              ),
            ),

            Expanded(
              child: modeActuel == 0 ? _construireSwiperRecettes() : _construireSwiperIngredients(),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.close, color: Colors.red, size: 30),
                      Text(modeActuel == 0 ? "Non merci" : "Je déteste (Bannir)", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.favorite, color: Colors.green, size: 30),
                      Text(modeActuel == 0 ? "Ajouter au carnet" : "J'aime bien", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireSwiperRecettes() {
    final plats = recettesAffichees;

    if (plats.isEmpty) {
      return const Center(child: Text("Tu as swipé toutes les recettes\n(ou tes allergies bloquent tout le reste !)", textAlign: TextAlign.center));
    }

    return CardSwiper(
      key: ValueKey('recettes_${plats.length}_$estModeSombreGlobal'),
      controller: _swiperControllerRecettes,
      cardsCount: plats.length,
      isLoop: false,
      numberOfCardsDisplayed: plats.length > 1 ? 2 : 1,
      onSwipe: (previousIndex, currentIndex, direction) {
        if (previousIndex >= plats.length) return false;

        final plat = plats[previousIndex];
        if (direction == CardSwiperDirection.right) {
          setState(() {
            mesRecettesGlobales.add(Map<String, dynamic>.from(plat));
          });
          sauvegarderDonneesLocales();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ ${plat['nom']} ajouté à ton carnet !"), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
        }
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        if (index >= plats.length) return const SizedBox.shrink();
        return _construireCarteRecette(plats[index]);
      },
    );
  }

  Widget _construireCarteRecette(Map<String, dynamic> plat) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        border: Border.all(color: Color(plat["couleur"]).withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(color: Color(plat["couleur"]), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
              child: Center(child: Icon(Icons.restaurant, size: 80, color: Colors.white.withOpacity(0.8))),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plat["nom"], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("${plat['tempsExact']} min", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 15),
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(plat["categorie"], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text("Ingrédients :", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: (plat["ingredients"] as List).map((ing) {
                      return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: estModeSombreGlobal ? Colors.grey.shade800 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(ing, style: TextStyle(fontSize: 13, color: estModeSombreGlobal ? Colors.white : Colors.black))
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireSwiperIngredients() {
    if (ingredientsANoter.isEmpty) {
      return const Center(child: Text("Tu as défini tous tes goûts !"));
    }

    return CardSwiper(
      key: ValueKey('ingredients_${ingredientsANoter.length}_$estModeSombreGlobal'),
      controller: _swiperControllerIngredients,
      cardsCount: ingredientsANoter.length,
      isLoop: false,
      numberOfCardsDisplayed: ingredientsANoter.length > 1 ? 2 : 1,
      onSwipe: (previousIndex, currentIndex, direction) {
        if (previousIndex >= ingredientsANoter.length) return false;

        final ingredient = ingredientsANoter[previousIndex];
        if (direction == CardSwiperDirection.left) {
          setState(() => ingredientsBannisGlobaux.add(ingredient));
          sauvegarderDonneesLocales();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚫 $ingredient banni !"), backgroundColor: Colors.red, duration: const Duration(seconds: 1)));
        } else if (direction == CardSwiperDirection.right) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❤️ Tu aimes : $ingredient"), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
        }
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        if (index >= ingredientsANoter.length) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text(ingredientsANoter[index], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Qu'en penses-tu ?", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}