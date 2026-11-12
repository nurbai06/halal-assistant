import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../history/bloc/history_bloc.dart';
import '../../history/screens/history_screen.dart';
import '../../ingredient_checker/screens/ingredient_checker_screen.dart';
import '../../ingredients/screens/ingredients_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/navigation_cubit.dart';
import 'home_screen.dart';

/// The four main tabs and the bottom navigation bar.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NavigationCubit, AppTab>(
      // Entering a tab reloads what it shows from the backend.
      listener: (context, tab) {
        switch (tab) {
          case AppTab.home:
            context.read<DashboardBloc>().add(const DashboardRequested());
          case AppTab.history:
            context.read<HistoryBloc>().add(const HistoryRequested());
          case AppTab.check || AppTab.ingredients:
            break;
        }
      },
      builder: (context, tab) {
        return Scaffold(
          body: IndexedStack(
            index: tab.index,
            children: const [
              HomeScreen(),
              IngredientCheckerScreen(),
              HistoryScreen(),
              IngredientsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (index) =>
                context.read<NavigationCubit>().select(AppTab.values[index]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check_rounded),
                label: 'Check',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Ingredients',
              ),
            ],
          ),
        );
      },
    );
  }
}
