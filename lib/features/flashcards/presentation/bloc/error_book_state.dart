import 'package:equatable/equatable.dart';

import '../../domain/entities/flashcard.dart';

abstract class ErrorBookState extends Equatable {
  const ErrorBookState();

  @override
  List<Object?> get props => [];
}

class ErrorBookInitial extends ErrorBookState {
  const ErrorBookInitial();
}

class ErrorBookLoading extends ErrorBookState {
  const ErrorBookLoading();
}

class ErrorBookLoaded extends ErrorBookState {
  final List<Flashcard> cards;

  const ErrorBookLoaded({required this.cards});

  @override
  List<Object?> get props => [cards];
}

class ErrorBookEmpty extends ErrorBookState {
  const ErrorBookEmpty();
}

class ErrorBookError extends ErrorBookState {
  final String message;

  const ErrorBookError({required this.message});

  @override
  List<Object?> get props => [message];
}
