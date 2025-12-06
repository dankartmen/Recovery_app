part of 'registration_bloc.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

class UpdateUsername extends RegistrationEvent {
  final String value;
  const UpdateUsername(this.value);
  @override
  List<Object?> get props => [value];
}

class UpdatePassword extends RegistrationEvent {
  final String value;
  const UpdatePassword(this.value);
  @override
  List<Object?> get props => [value];
}

class UpdateConfirmPassword extends RegistrationEvent {
  final String value;
  const UpdateConfirmPassword(this.value);
  @override
  List<Object?> get props => [value];
}

class TogglePasswordVisibility extends RegistrationEvent {}

class ToggleConfirmPasswordVisibility extends RegistrationEvent {}

class ValidateForm extends RegistrationEvent {}

class RegisterUser extends RegistrationEvent {}

class ClearErrors extends RegistrationEvent {}