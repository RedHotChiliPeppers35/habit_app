import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:habit_app/core/link/auth_link_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_app/core/env.dart';
import 'package:habit_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const ProviderScope(child: AuthLinkHandler(child: MyApp())));
}
