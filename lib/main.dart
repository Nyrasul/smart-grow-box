import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Нужно для проверки платформы

import 'providers/grow_box_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/control_screen.dart';
import 'screens/logic_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // 🌐 НАСТРОЙКИ ДЛЯ CHROME (Вставь свои данные из Firebase Console -> Web App)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAaW1GHNd6sitLdYX0xj2sdUxeS9mCQgQg", // Например: "AIzaSyD..."
          appId: "1:146513060240:web:a08413e60ffacdc1391315",   // Например: "1:12345678:web:..."
          messagingSenderId: "146513060240",
          projectId: "smartgrowbox-1f7e8", // Например: "smart-grow-box-123"
          databaseURL: "https://smartgrowbox-1f7e8-default-rtdb.firebaseio.com",
          // Эти два поля тоже возьми из консоли (если их нет - удали эти строки)
          storageBucket: "smartgrowbox-1f7e8.firebasestorage.app", 
          authDomain: "smartgrowbox-1f7e8.firebaseapp.com",
        ),
      );
    } else {
      // 📱 НАСТРОЙКИ ДЛЯ ANDROID / IOS (Читает из файла google-services.json)
      await Firebase.initializeApp();
    }
    print("✅ Firebase успешно подключен!");
  } catch (e) {
    print("❌ Ошибка Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GrowBoxProvider()),
      ],
      child: const SmartGrowApp(),
    ),
  );
}

class SmartGrowApp extends StatelessWidget {
  const SmartGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Grow Box',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF2979FF),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.robotoMonoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ControlScreen(),
    const LogicScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF00E676).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF00E676)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: Color(0xFF00E676)),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: Color(0xFF00E676)),
            label: 'Logic',
          ),
        ],
      ),
    );
  }
}