import 'package:equatable/equatable.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object> get props => [];
}

class MenuLoadRequested extends MenuEvent {
  final DateTime? date;

  const MenuLoadRequested({this.date});

  @override
  List<Object> get props => [date ?? 'null'];
}

class MenuDaySelected extends MenuEvent {
  final DateTime selectedDate;

  const MenuDaySelected(this.selectedDate);

  @override
  List<Object> get props => [selectedDate];
}
