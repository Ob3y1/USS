part of 'user_cubit.dart';

abstract class UserState {}

class UserInitial extends UserState {}

class SignInLoading extends UserState {}

class SignInSuccess extends UserState {}

class SignInFailure extends UserState {
  final String errMessage;
  SignInFailure({required this.errMessage});
}

final class SignUpLoading extends UserState {}

final class SignUpSuccess extends UserState {}

final class SignUpFailure extends UserState {
  final String errMessage;

  SignUpFailure(this.errMessage); // تمرير قيمة errMessage بشكل مباشر
}

final class UserLoading extends UserState {
  UserLoading();
}

final class UserSuccess extends UserState {}

final class UserFailure extends UserState {
  final String errMessage;

  UserFailure(this.errMessage); // تمرير قيمة errMessage بشكل مباشر
}

final class EditUserLoading extends UserState {}

final class EditUserSuccess extends UserState {}

final class EditUserFailure extends UserState {
  final String errMessage;

  EditUserFailure(this.errMessage); // تمرير قيمة errMessage بشكل مباشر
}



class UserError extends UserState {
  final String message;
  UserError(this.message);
}

abstract class UserqState {}

class UserqInitial extends UserState {}

class UserqLoading extends UserState {
  final User user;
  UserqLoading(this.user);
}

class UserLoaded extends UserState {
  final User user;
  UserLoaded(this.user);
}

class UserqError extends UserState {
  final String message;
  UserqError(this.message);
}
abstract class SubjectState {}

class SubjectInitial extends SubjectState {}

class SubjectLoading extends SubjectState {}

class SubjectSuccess extends SubjectState {
  final Map<String, dynamic> subject;

  SubjectSuccess(this.subject);
}

class SubjectFailure extends SubjectState {
  final String error;

  SubjectFailure(this.error);
}


class UserSchedulesSentSuccess extends UserState {
  final dynamic data;
  UserSchedulesSentSuccess(this.data);
}

class UserSchedulesSentFailure extends UserState {
  final String error;
  UserSchedulesSentFailure(this.error);
}
