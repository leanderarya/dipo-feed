import 'package:flutter/material.dart';

import '../../data/models/bahan_pakan.dart';
import '../../data/sources/bahan_pakan_local_source.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  late Future<List<BahanPakan>> _futureBahanPakan;

  @override
  void initState() {
    super.initState();
    _futureBahanPakan = BahanPakanLocalSource().ambilSemuaBahanPakan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DipoFeed'),
      ),
      body: FutureBuilder<List<BahanPakan>>(
        future: _futureBahanPakan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data ?? [];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                child: ListTile(
                  title: Text(item.nama),
                  subtitle: Text(
                    'Kategori: ${item.kategori} | Protein: ${item.protein}% | TDN: ${item.tdn}%',
                  ),
                  trailing: Text('Rp ${item.hargaDefault.toStringAsFixed(0)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}