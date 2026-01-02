import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(EchoStatusApp(storageService: storageService));
}

class EchoStatusApp extends StatelessWidget {
  final StorageService storageService;

  const EchoStatusApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Status',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF09090B),
          primary: Colors.blue,
          secondary: Colors.blue.shade300,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF09090B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF18181B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF27272A)),
          ),
        ),
        dividerColor: const Color(0xFF27272A),
        dialogTheme: const DialogTheme(
          backgroundColor: Color(0xFF18181B),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF18181B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF27272A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF27272A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
      home: HomeScreen(storageService: storageService),
    );
  }
}
