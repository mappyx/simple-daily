import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/data_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/system_tray_service.dart';
import 'services/task_automation_service.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await windowManager.ensureInitialized();
  await NotificationService().init();
  await SystemTrayService().init();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1100, 750),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: AppConstants.appName,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final dataProvider = DataProvider();
  // Initialize Automation Service which keeps running
  final automationService = TaskAutomationService(dataProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataProvider),
      ],
      child: const SimpleDailyApp(),
    ),
  );
}

class SimpleDailyApp extends StatelessWidget {
  const SimpleDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
