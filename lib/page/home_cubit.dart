import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/commons/enums.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  void onPlayPressed() {
    emit(state.copyWith(isLoading: true));

    Future.delayed(const Duration(milliseconds: 300), () {
      emit(state.copyWith(isLoading: false));
    });
  }

  void changeTab(TabItem tabItem) {
    emit(state.copyWith(selected: tabItem));
  }

}
