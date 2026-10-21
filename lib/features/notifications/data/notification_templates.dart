// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: Notification message templates with warm, friendly tone

// TODO(D): Implement NotificationTemplates according to project specification

// Owner: D
// Notification messages agreed in section 4.2.4 of the team guide.

/// The title and body used when writing a notification.
class NotificationMessage {
  const NotificationMessage({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class NotificationTemplates {
  static NotificationMessage newExpense({
    required String payer,
    required String title,
    required int amount,
  }) {
    return NotificationMessage(
      title: 'New shared cost',
      body: '$payer added $title. Your share is RWF ${_formatAmount(amount)}.',
    );
  }

  static NotificationMessage nudge({
    required String name,
    required int amount,
    required String household,
  }) {
    return NotificationMessage(
      title: 'A friendly reminder',
      body:
          'Hey $name, a gentle reminder about '
          'RWF ${_formatAmount(amount)} for $household. '
          'Tap to see the details.',
    );
  }

  static NotificationMessage settled({
    required String name,
    required String method,
  }) {
    return NotificationMessage(
      title: 'Balance settled',
      body: '$name marked your balance as settled via $method.',
    );
  }

  static NotificationMessage swapRequest({
    required String name,
    required String chore,
  }) {
    return NotificationMessage(
      title: 'Swap request',
      body: '$name would like to swap "$chore". Can you help?',
    );
  }

  static NotificationMessage swapResponse({
    required String name,
    required bool accepted,
  }) {
    return NotificationMessage(
      title: 'Swap update',
      body: accepted
          ? '$name accepted your swap request.'
          : "$name can't swap this time.",
    );
  }

  /// Formats whole RWF amounts, for example 14000 becomes 14,000.
  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
