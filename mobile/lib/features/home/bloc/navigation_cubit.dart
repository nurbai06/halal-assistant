import 'package:flutter_bloc/flutter_bloc.dart';

/// The tabs of the bottom navigation bar, in order.
enum AppTab { home, check, history, ingredients }

/// Which tab is selected.
class NavigationCubit extends Cubit<AppTab> {
  NavigationCubit() : super(AppTab.home);

  void select(AppTab tab) => emit(tab);
}
