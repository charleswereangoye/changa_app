part of 'swap_inbox_cubit.dart';

/// A short message for a snackbar. The id makes two equal messages in a
/// row still count as new.
class InboxNotice extends Equatable {
  const InboxNotice(this.id, this.text, {this.isError = false});

  final int id;
  final String text;
  final bool isError;

  @override
  List<Object?> get props => [id, text, isError];
}

class SwapInboxState extends Equatable {
  const SwapInboxState({
    this.requests = const [],
    this.choreTitles = const {},
    this.respondingIds = const {},
    this.notice,
  });

  /// Open requests other people have sent me, newest first.
  final List<SwapRequest> requests;

  /// Chore names by id, so a request can say which chore it is about.
  final Map<String, String> choreTitles;
  final Set<String> respondingIds;
  final InboxNotice? notice;

  String titleFor(SwapRequest request) =>
      choreTitles[request.choreId] ?? 'a chore';

  SwapInboxState copyWith({
    List<SwapRequest>? requests,
    Map<String, String>? choreTitles,
    Set<String>? respondingIds,
    InboxNotice? notice,
    bool clearNotice = false,
  }) {
    return SwapInboxState(
      requests: requests ?? this.requests,
      choreTitles: choreTitles ?? this.choreTitles,
      respondingIds: respondingIds ?? this.respondingIds,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [requests, choreTitles, respondingIds, notice];
}
