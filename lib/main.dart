import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/bahan_pakan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(BahanPakanAdapter());
  
  // Open Boxes
  await Hive.openBox<BahanPakan>('bahan_pakan_box');
  
  runApp(const DipoFeedApp());
}
