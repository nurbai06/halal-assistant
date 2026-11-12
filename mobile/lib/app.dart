import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';
import 'features/history/bloc/history_bloc.dart';
import 'features/home/bloc/dashboard_bloc.dart';
import 'features/home/bloc/navigation_cubit.dart';
import 'features/home/screens/main_shell.dart';
import 'features/ingredient_checker/bloc/ingredient_checker_bloc.dart';
import 'features/ingredient_checker/repository/halal_repository.dart';
import 'features/ingredients/bloc/ingredients_bloc.dart';

class HalalAssistantApp extends StatelessWidget {
  const HalalAssistantApp({super.key, required this.repository});

  final HalalRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(
            create: (_) =>
                DashboardBloc(repository)..add(const DashboardRequested()),
          ),
          BlocProvider(
            create: (_) =>
                HistoryBloc(repository)..add(const HistoryRequested()),
          ),
          BlocProvider(
            create: (_) =>
                IngredientsBloc(repository)..add(const IngredientsRequested()),
          ),
          BlocProvider(create: (_) => IngredientCheckerBloc(repository)),
        ],
        child: MaterialApp(
          title: 'Halal Assistant',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const MainShell(),
        ),
      ),
    );
  }
}
