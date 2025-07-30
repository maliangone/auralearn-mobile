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

  const HistoryLoaded({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    this.currentSubject,
  });

  @override
  List<Object?> get props => [items, hasMore, currentPage, currentSubject];

  HistoryLoaded copyWith({
    List<HistoryItem>? items,
    bool? hasMore,
    int? currentPage,
    String? currentSubject,
  }) {
    return HistoryLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentSubject: currentSubject ?? this.currentSubject,
    );
  }
}

class HistoryEmpty extends HistoryState {
  final String? subject;

  const HistoryEmpty({this.subject});

  @override
  List<Object?> get props => [subject];
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