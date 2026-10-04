import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigationTabChangedEvent extends NavigationEvent {
  final int tabIndex;
  const NavigationTabChangedEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}
