import 'package:flutter/material.dart';
import 'donnees_globales.dart';
import 'ecran_bibliotheque.dart';
import 'ecran_planificateur.dart';
import 'ecran_courses.dart';
import 'ecran_accueil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await chargerDonneesLocales();

  runApp(const MonApplication());
}

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    // Le ValueListenableBuilder écoute en direct le "themeNotifier"
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Miam',

          // --- THÈME CLAIR ---
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: Colors.grey.shade100,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),

          // --- THÈME SOMBRE ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: const Color(0xFF121212), // Gris très foncé
            cardColor: const Color(0xFF1E1E1E), // Cartes légèrement plus claires
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.greenAccent,
              unselectedItemColor: Colors.grey,
            ),
          ),

          themeMode: currentMode, // C'est ici que la magie opère
          home: const NavigationPrincipale(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class NavigationPrincipale extends StatefulWidget {
  const NavigationPrincipale({super.key});

  @override
  State<NavigationPrincipale> createState() => _NavigationPrincipaleState();
}

class _NavigationPrincipaleState extends State<NavigationPrincipale> {
  int _indexSelectionne = 0;

  final List<Widget> _ecrans = [
    const EcranAccueil(),
    // const EcranSwipe(),
    const EcranBibliotheque(),
    const EcranPlanificateur(),
    const EcranCourses(),
  ];

  void _changerOnglet(int index) {
    setState(() {
      _indexSelectionne = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ecrans[_indexSelectionne],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexSelectionne,
        onTap: _changerOnglet,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          // BottomNavigationBarItem(icon: Icon(Icons.swipe), label: 'Découvrir'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Recettes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Courses'),
        ],
      ),
    );
  }
}