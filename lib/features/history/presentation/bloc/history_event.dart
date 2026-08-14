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

// ---------------------------------------------------------------------------
// Phase-B archive events
// ---------------------------------------------------------------------------

/// Dispatched (debounced) when the search TextField value changes.
class HistorySearchChanged extends HistoryEvent {
  final String query;

  const HistorySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched when a subject filter chip is tapped; [subject] null means "全部".
class HistorySubjectFilterChanged extends HistoryEvent {
  final String? subject;

  const HistorySubjectFilterChanged(this.subject);

  @override
  List<Object?> get props => [subject];
}

/// Dispatched after the tag-edit dialog confirms; replaces all tags for [id].
class HistoryTagsEdited extends HistoryEvent {
  final String id;
  final List<String> tags;

  const HistoryTagsEdited({required this.id, required this.tags});

  @override
  List<Object?> get props => [id, tags];
}

/// Clears the active query and subject filter, reloading the full list.
class HistoryFiltersCleared extends HistoryEvent {
  const HistoryFiltersCleared();
}

/// Requests a reload of the distinct subject list (e.g. after tag/subject edit).
class HistorySubjectsLoadRequested extends HistoryEvent {
  const HistorySubjectsLoadRequested();
} 