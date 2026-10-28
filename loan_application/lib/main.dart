import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:loan_application/user/Home2.dart';
import 'package:loan_application/user/login.dart';
import 'package:loan_application/user/session_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.green,
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      debugShowCheckedModeBanner: false,
      title: "Batch 5",
      home: const SessionPage(),


    );
  }
}