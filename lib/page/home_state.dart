part of 'home_cubit.dart';

class HomeState extends Equatable {

  final bool isLoading;
  final TabItem? selected;

  const HomeState(
   {
    this.isLoading = false,
    this.selected = TabItem.home,
   }
  );

  HomeState copyWith(
      {bool? isLoading,
       TabItem? selected}) {

    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      selected:selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    selected,
  ];
}
