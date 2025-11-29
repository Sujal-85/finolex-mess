import 'package:flutter_bloc/flutter_bloc.dart';
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
      await Future.delayed(
        const Duration(milliseconds: 1500),
      ); // Simulate API delay

      // Mock Data
      final List<Map<String, dynamic>> mockItems = [
        {
          'id': '1',
          'name': 'Veg Thali',
          'description': 'Chapati, Rice, Dal, 2 Sabji, Salad, Pickle',
          'price': 60.0,
          'rating': 4.5,
          'image': 'assets/images/thali.png', // Placeholder
          'isVeg': true,
          'category': 'Lunch',
        },
        {
          'id': '2',
          'name': 'Chicken Biryani',
          'description': 'Aromatic basmati rice cooked with spices and chicken',
          'price': 120.0,
          'rating': 4.8,
          'image': 'assets/images/biryani.png', // Placeholder
          'isVeg': false,
          'category': 'Special',
        },
        {
          'id': '3',
          'name': 'Masala Dosa',
          'description':
              'Crispy crepe made from fermented rice and lentil batter',
          'price': 50.0,
          'rating': 4.6,
          'image': 'assets/images/dosa.png', // Placeholder
          'isVeg': true,
          'category': 'Breakfast',
        },
        {
          'id': '4',
          'name': 'Paneer Butter Masala',
          'description':
              'Rich and creamy curry made with paneer, spices, onions, tomatoes',
          'price': 110.0,
          'rating': 4.7,
          'image': 'assets/images/paneer.png', // Placeholder
          'isVeg': true,
          'category': 'Dinner',
        },
      ];

      emit(state.copyWith(status: MenuStatus.success, menuItems: mockItems));
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
