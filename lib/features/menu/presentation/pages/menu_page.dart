import 'package:flutter/material.dart';
import 'package:campus_eats/core/theme/app_theme.dart';
import 'package:campus_eats/core/theme/app_spacing.dart';
import 'package:campus_eats/core/widgets/state_view.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Remplacez ce placeholder par le vrai contenu du menu lorsque disponible.
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: StateView(
          isLoading: false,
          isEmpty: false,
          errorMessage: null,
          child: ListView.builder(
            itemCount: 5, // exemple de 5 cartes fictives
            itemBuilder: (context, index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Plat Exemple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: AppSpacing.xs),
                      Text('Description courte du plat.', style: TextStyle(fontSize: 14)),
                      SizedBox(height: AppSpacing.s),
                      Text('12,00 €', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')), 
      body: const Center(child: Text('Page Menu – affichage du menu étudiant')),
    );
  }
}
