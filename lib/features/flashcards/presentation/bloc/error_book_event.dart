import 'package:equatable/equatable.dart';

abstract class ErrorBookEvent extends Equatable {
  const ErrorBookEvent();

  @override
  List<Object?> get props => [];
}

/// Load every flashcard, newest-first.
class ErrorBookLoadRequested extends ErrorBookEvent {
  const ErrorBookLoadRequested();
}

/// Delete a single card by id, then refresh the in-memory list.
class ErrorBookDeleteRequested extends ErrorBookEvent {
  final String id;

  const ErrorBookDeleteRequested({required this.id});

  @override
  List<Object?> get props => [id];
}
