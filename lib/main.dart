import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/driver_home.dart';
import 'screens/admin_dashboard.dart';
import 'config/constant.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _home;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() {
        _home = const LoginScreen();
        _loading = false;
      });
      return;
    }
    // Check if user is admin (only if email is not null)
    if (user.email != null) {
      final admin = await client
          .from('admin')
          .select()
          .eq('email', user.email!)
          .maybeSingle();
      if (admin != null) {
        setState(() {
          _home = const AdminDashboard();
          _loading = false;
        });
        return;
      }
    }
    // Check if user is driver
    final driver = await client
        .from('drivers')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (driver != null) {
      setState(() {
        _home = const DriverHomeScreen();
        _loading = false;
      });
      return;
    }
    // Default to login if not found
    setState(() {
      _home = const LoginScreen();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniTrack',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _home,
    );
  }
}
