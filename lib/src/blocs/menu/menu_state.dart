import 'package:equatable/equatable.dart';

enum MenuStatus { initial, loading, success, failure }

class MenuState extends Equatable {
  final MenuStatus status;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> menuItems;
  final String? errorMessage;

  const MenuState({
    this.status = MenuStatus.initial,
    required this.selectedDate,
    this.menuItems = const [],
    this.errorMessage,
  });

  MenuState copyWith({
    MenuStatus? status,
    DateTime? selectedDate,
    List<Map<String, dynamic>>? menuItems,
    String? errorMessage,
  }) {
    return MenuState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      menuItems: menuItems ?? this.menuItems,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, selectedDate, menuItems, errorMessage];
}
