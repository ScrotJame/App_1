import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'upadte_profile_state.dart';

class UpadteProfileCubit extends Cubit<UpadteProfileState> {
  UpadteProfileCubit() : super(UpadteProfileInitial());
}
