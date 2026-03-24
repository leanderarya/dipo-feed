import 'package:flutter/material.dart';

import 'features/cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';

class DipoFeedApp extends StatelessWidget {
  const DipoFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DipoFeed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const CekKandunganNutrisiScreen(),
    );
  }
}
