import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(MenuState(selectedDate: DateTime.now())) {
    on<MenuLoadRequested>(_onLoadRequested);
    on<MenuDaySelected>(_onDaySelected);
  }

  Future<void> _onLoadRequested(
    MenuLoadRequested event,
    Emitter<MenuState> emit,
  ) async {
    emit(state.copyWith(status: MenuStatus.loading));
    try {
      final api = ApiService();
      // Format date to 'Monday', 'Tuesday', etc.
      final date = event.date ?? DateTime.now();
      final day = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][date.weekday - 1];

      final response = await api.get('/menu', queryParameters: {'day': day});
      final List<dynamic> data = response.data;
      final List<Map<String, dynamic>> menuItems =
          List<Map<String, dynamic>>.from(data);

      emit(state.copyWith(status: MenuStatus.success, menuItems: menuItems));
    } catch (e) {
      emit(
        state.copyWith(
          status: MenuStatus.failure,
          errorMessage: 'Failed to load menu',
        ),
      );
    }
  }

  void _onDaySelected(MenuDaySelected event, Emitter<MenuState> emit) {
    emit(state.copyWith(selectedDate: event.selectedDate));
    add(MenuLoadRequested(date: event.selectedDate));
  }
}
