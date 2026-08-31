import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:'https://ivxpitsxpdfevdtigjoz.supabase.co',
    anonKey:'sb_publishable_j1Lz8UZ2qc32q0yHNBzpRQ_oHnNwBaA',
  );

  runApp(const AppNavigation());
}