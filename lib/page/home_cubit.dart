import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  void onPlayPressed() {
    emit(state.copyWith(isLoading: true));
    // TODO: navigate to game
    Future.delayed(const Duration(milliseconds: 300), () {
      emit(state.copyWith(isLoading: false));
    });
  }

}
