import 'package:flutter/material.dart';
import 'ecran_swipe.dart';
import 'ecran_bibliotheque.dart';
import 'ecran_planificateur.dart';
import 'ecran_courses.dart';

void main() {
  runApp(const MonAppRepas());
}

class MonAppRepas extends StatelessWidget {
  const MonAppRepas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organisateur de Repas',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const NavigationPrincipale(),
    );
  }
}

class NavigationPrincipale extends StatefulWidget {
  const NavigationPrincipale({super.key});

  @override
  State<NavigationPrincipale> createState() => _NavigationPrincipaleState();
}

class _NavigationPrincipaleState extends State<NavigationPrincipale> {
  int _indexActuel = 0;

  // Nos 5 écrans (vides pour l'instant)
  final List<Widget> _ecrans = [
    const Center(child: Text("1. Accueil (Le Menu)")),
    const EcranSwipe(),
    const EcranBibliotheque(),
    const EcranPlanificateur(),
    const EcranCourses(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon App de Repas')),
      body: _ecrans[_indexActuel],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexActuel,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _indexActuel = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.swipe), label: 'Swipe'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Recettes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Courses'),
        ],
      ),
    );
  }
}