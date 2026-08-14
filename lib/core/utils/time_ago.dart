import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Shared relative-time formatting ("3 分钟前" / "yesterday" / …).
///
/// Centralises what used to be copy-pasted across home, history and the
/// question flow — and routes every string through l10n.
String formatTimeAgo(BuildContext context, DateTime dt) {
  final l = AppLocalizations.of(context);
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return l.timeJustNow;
  if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
  if (diff.inDays == 1) return l.timeYesterday;
  if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
  return '${dt.year}/${dt.month}/${dt.day}';
}
