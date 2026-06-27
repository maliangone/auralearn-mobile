import 'package:equatable/equatable.dart';
import '../../domain/entities/history_item.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoadingMore extends HistoryState {
  final List<HistoryItem> items;

  const HistoryLoadingMore({required this.items});

  @override
  List<Object?> get props => [items];
}

class HistoryLoaded extends HistoryState {
  final List<HistoryItem> items;
  final bool hasMore;
  final int currentPage;
  final String? currentSubject;
  /// Active free-text search query (empty string = no query).
  final String currentQuery;
  /// Distinct subject labels for filter chips (may be empty).
  final List<String> subjects;
  /// True when there are filters active but they returned no rows
  /// (different UX from "database is empty").
  final bool isFilteredEmpty;

  const HistoryLoaded({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    this.currentSubject,
    this.currentQuery = '',
    this.subjects = const [],
    this.isFilteredEmpty = false,
  });

  @override
  List<Object?> get props => [
        items,
        hasMore,
        currentPage,
        currentSubject,
        currentQuery,
        subjects,
        isFilteredEmpty,
      ];

  HistoryLoaded copyWith({
    List<HistoryItem>? items,
    bool? hasMore,
    int? currentPage,
    String? currentSubject,
    String? currentQuery,
    List<String>? subjects,
    bool? isFilteredEmpty,
  }) {
    return HistoryLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentSubject: currentSubject ?? this.currentSubject,
      currentQuery: currentQuery ?? this.currentQuery,
      subjects: subjects ?? this.subjects,
      isFilteredEmpty: isFilteredEmpty ?? this.isFilteredEmpty,
    );
  }
}

class HistoryEmpty extends HistoryState {
  final String? subject;
  final String currentQuery;
  final List<String> subjects;
  /// True when there were filters active but no rows matched — distinct from
  /// "the entire archive is empty".
  final bool isFilteredEmpty;

  const HistoryEmpty({
    this.subject,
    this.currentQuery = '',
    this.subjects = const [],
    this.isFilteredEmpty = false,
  });

  @override
  List<Object?> get props => [subject, currentQuery, subjects, isFilteredEmpty];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class HistoryItemDeleting extends HistoryState {
  final List<HistoryItem> items;
  final String deletingItemId;

  const HistoryItemDeleting({
    required this.items,
    required this.deletingItemId,
  });

  @override
  List<Object?> get props => [items, deletingItemId];
}

class HistoryItemDeleted extends HistoryState {
  final List<HistoryItem> items;
  final String deletedItemId;

  const HistoryItemDeleted({
    required this.items,
    required this.deletedItemId,
  });

  @override
  List<Object?> get props => [items, deletedItemId];
}

class HistoryClearing extends HistoryState {
  const HistoryClearing();
}

class HistoryCleared extends HistoryState {
  const HistoryCleared();
} 