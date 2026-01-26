import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    await localNotifier.setup(
      appName: 'SimpleDaily',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> showDailyReminder(int taskCount) async {
    LocalNotification notification = LocalNotification(
      title: "SimpleDaily Reminder",
      body: "You have $taskCount active tasks to review today.",
    );
    notification.onShow = () {
      print('onShow ${notification.identifier}');
    };
    notification.onClick = () {
      print('onClick ${notification.identifier}');
      notification.close();
    };
    notification.show();
  }

  // In a real app, use a background worker or cron-like scheduling.
  // For 'Simple', we check on app launch if we haven't notified today.
}
