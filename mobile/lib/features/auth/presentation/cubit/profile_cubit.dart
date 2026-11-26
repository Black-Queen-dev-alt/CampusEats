import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_eats_mobile/features/auth/domain/auth_validators.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

enum ProfileStatus { idle, saving, saved, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.idle,
    this.message,
    this.fieldErrors = const {},
  });

  final ProfileStatus status;
  final String? message;
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [status, message, fieldErrors];
}

/// Modification du nom (PATCH /me). Met aussi à jour l'AuthBloc.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required AuthRepository repository, required AuthBloc authBloc})
    : _repository = repository,
      _authBloc = authBloc,
      super(const ProfileState());

  final AuthRepository _repository;
  final AuthBloc _authBloc;

  Future<void> saveName(String fullName) async {
    final error = AuthValidators.fullName(fullName);
    if (error != null) {
      emit(
        ProfileState(
          status: ProfileStatus.failure,
          message: error,
          fieldErrors: {'fullName': error},
        ),
      );
      return;
    }
    emit(const ProfileState(status: ProfileStatus.saving));
    try {
      final user = await _repository.updateProfile(fullName: fullName.trim());
      _authBloc.add(UserUpdated(user));
      emit(
        const ProfileState(
          status: ProfileStatus.saved,
          message: 'Profil mis à jour',
        ),
      );
    } on Failure catch (failure) {
      emit(
        ProfileState(
          status: ProfileStatus.failure,
          message: failure.message,
          fieldErrors: failure is ValidationFailure
              ? failure.fieldErrors
              : const {},
        ),
      );
    }
  }
}
