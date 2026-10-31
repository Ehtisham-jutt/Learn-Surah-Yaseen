import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

// Surah number 36 = Yaseen.
// Editions: Arabic text, Urdu translation, Mishary Alafasy audio (per ayah).
const String apiUrl =
    'https://api.alquran.cloud/v1/surah/36/editions/quran-uthmani,ur.jalandhry,ar.alafasy';

void main() => runApp(const YaseenApp());

class Ayah {
  final int number;
  final String arabic;
  final String urdu;
  final String audio;
  Ayah(this.number, this.arabic, this.urdu, this.audio);
}

class YaseenApp extends StatefulWidget {
  const YaseenApp({super.key});

  @override
  State<YaseenApp> createState() => _YaseenAppState();
}

class _YaseenAppState extends State<YaseenApp> {
  bool dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn Surah Yaseen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: SurahPage(
        dark: dark,
        onToggleTheme: () => setState(() => dark = !dark),
      ),
    );
  }
}

class SurahPage extends StatefulWidget {
  final bool dark;
  final VoidCallback onToggleTheme;
  const SurahPage({super.key, required this.dark, required this.onToggleTheme});

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  final AudioPlayer player = AudioPlayer();
  List<Ayah> ayahs = [];
  bool loading = true;
  String? error;
  double arabicSize = 28;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw Exception('Server error (${res.statusCode})');
      }
      final body = json.decode(utf8.decode(res.bodyBytes));
      final editions = body['data'] as List;

      final Map<String, List> byId = {};
      for (final e in editions) {
        byId[e['edition']['identifier'] as String] = e['ayahs'] as List;
      }
      final arabic = byId['quran-uthmani']!;
      final urdu = byId['ur.jalandhry']!;
      final audio = byId['ar.alafasy']!;

      final List<Ayah> result = [];
      for (int i = 0; i < arabic.length; i++) {
        final int n = arabic[i]['numberInSurah'] as int;
        String text = (arabic[i]['text'] as String).trim();
        // Some editions put Bismillah in front of the first ayah; remove it.
        if (n == 1) {
          final words = text.split(' ');
          if (words.length > 4) {
            text = words.sublist(4).join(' ');
          }
        }
        result.add(Ayah(
          n,
          text,
          (urdu[i]['text'] as String).trim(),
          audio[i]['audio'] as String,
        ));
      }

      await player.setAudioSource(
        ConcatenatingAudioSource(
          children:
              result.map((a) => AudioSource.uri(Uri.parse(a.audio))).toList(),
        ),
      );

      setState(() {
        ayahs = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Data load nahi ho saka. Internet check karein.\n($e)';
        loading = false;
      });
    }
  }

  Future<void> playFrom(int index) async {
    await player.seek(Duration.zero, index: index);
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Surah Yaseen'),
        actions: [
          IconButton(
            tooltip: 'Font chhota',
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(
                () => arabicSize = (arabicSize - 2).clamp(20, 50).toDouble()),
          ),
          IconButton(
            tooltip: 'Font bara',
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(
                () => arabicSize = (arabicSize + 2).clamp(20, 50).toDouble()),
          ),
          IconButton(
            tooltip: 'Dark mode',
            icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: ayahs.isEmpty ? null : _buildPlayerBar(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: load, child: const Text('Dobara koshish')),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<int?>(
      stream: player.currentIndexStream,
      builder: (context, snap) {
        final current = snap.data;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ayahs.length,
          itemBuilder: (context, i) {
            final a = ayahs[i];
            final selected = current == i;
            return Card(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
