import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryLoadRequested extends HistoryEvent {
  final int page;
  final int limit;
  final String? subject;
  final bool refresh;

  const HistoryLoadRequested({
    this.page = 1,
    this.limit = 20,
    this.subject,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, limit, subject, refresh];
}

class HistoryItemDeleteRequested extends HistoryEvent {
  final String itemId;

  const HistoryItemDeleteRequested({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

class HistoryClearRequested extends HistoryEvent {
  const HistoryClearRequested();
}

class HistoryLoadMoreRequested extends HistoryEvent {
  const HistoryLoadMoreRequested();
}

class HistoryFilterChanged extends HistoryEvent {
  final String? subject;

  const HistoryFilterChanged({this.subject});

  @override
  List<Object?> get props => [subject];
} 