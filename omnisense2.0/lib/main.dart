import 'package:flutter/material.dart';
import 'features/camera/presentation/camera_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OmniSenseApp());
}

class OmniSenseApp extends StatelessWidget {
  const OmniSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniSense AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const CameraHomeScreen(),
    );
  }
}
