import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/neon_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => VehicleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehicleProvider>(context);

    // Dark Neon Theme (Default)
    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NeonColors.background,
      fontFamily: 'Roboto', // Premium layout typography
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: NeonColors.primary,
        secondary: NeonColors.secondary,
        background: NeonColors.background,
        surface: NeonColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: NeonColors.secondary,
        selectionColor: NeonColors.primary,
        selectionHandleColor: NeonColors.secondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return NeonColors.secondary;
          return NeonColors.textSecondary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return NeonColors.primary.withOpacity(0.5);
          return Colors.black26;
        }),
      ),
    );

    // Premium Light Theme
    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F6FA),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1C1C24)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C24),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: NeonColors.primary,
        secondary: NeonColors.secondary,
        background: Color(0xFFF6F6FA),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: NeonColors.primary,
      ),
    );

    return MaterialApp(
      title: 'Mileage Calculator',
      debugShowCheckedModeBanner: false,
      theme: provider.isDarkMode ? darkTheme : lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
