import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class EcranSwipe extends StatefulWidget {
  const EcranSwipe({super.key});

  @override
  State<EcranSwipe> createState() => _EcranSwipeState();
}

class _EcranSwipeState extends State<EcranSwipe> {
  // Fausses données pour tester le visuel
  final List<Map<String, String>> platsTemp = [
    {"nom": "Poulet rôti & Légumes", "image": "https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?q=80&w=500&auto=format&fit=crop"},
    {"nom": "Pâtes au Pesto", "image": "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?q=80&w=500&auto=format&fit=crop"},
    {"nom": "Salade César", "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500&auto=format&fit=crop"},
    {"nom": "Burger Maison", "image": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=500&auto=format&fit=crop"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Que penses-tu de ces plats ?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: CardSwiper(
                cardsCount: platsTemp.length,
                onSwipe: _onSwipe,
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final plat = platsTemp[index];
                  return _construireCarte(plat);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text("⬅️ Non  |  Oui ➡️", style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // La logique quand on glisse la carte
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) {
      debugPrint("Ajouté aux favoris !");
    } else if (direction == CardSwiperDirection.left) {
      debugPrint("Plat ignoré.");
    }
    return true; // true = autoriser le swipe
  }

  // Le design de la carte
  Widget _construireCarte(Map<String, String> plat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(plat["image"]!),
          fit: BoxFit.cover,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.black87, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.center,
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
        child: Text(
          plat["nom"]!,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}