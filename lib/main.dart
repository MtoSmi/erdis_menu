import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('it_IT', null).then((_) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.red, // Set the status bar color to bright red
    ));
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menù mensa Colle Paradiso',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red).copyWith(
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Menù mensa Colle Paradiso'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _htmlContent = '';
  String _menuUrl = '';
  final Map<String, List<String>> lunchCourses = {
    'Primo': <String>[],
    'Secondo': <String>[],
    'Contorno': <String>[],
    'Frutta': <String>[],
    'Dessert': <String>[]
  };
  final Map<String, List<String>> dinnerCourses = {
    'Primo': <String>[],
    'Secondo': <String>[],
    'Contorno': <String>[],
    'Frutta': <String>[],
    'Dessert': <String>[]
  };

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    String currentDate = DateFormat('yyyy_MM_dd').format(DateTime.now());
    _menuUrl = 'https://menu.erdis.it/Mensa_Paradiso/Menu_Del_Giorno_${currentDate}_Paradiso.html';
    final response = await http.get(Uri.parse(_menuUrl));

    if (response.statusCode == 200) {
      _htmlContent = response.body;
      final document = html_parser.parse(_htmlContent);
      final body = document.body;
      if (body != null) {
        final elements = body.querySelectorAll('td');
        bool foundPranzo = false;
        bool foundCena = false;
        String? currentCourse;

        for (var element in elements) {
          String cleanedText = element.text.replaceAll(
              RegExp(r'[0-9,]'), '').trim();
          if (cleanedText.contains('Pranzo')) {
            foundPranzo = true;
            foundCena = false;
            currentCourse = null;
          } else if (cleanedText.contains('Cena')) {
            foundPranzo = false;
            foundCena = true;
            currentCourse = null;
          } else if (foundPranzo || foundCena) {
            if (cleanedText.contains('Primo') ||
                cleanedText.contains('Secondo') ||
                cleanedText.contains('Contorno') ||
                cleanedText.contains('Frutta') ||
                cleanedText.contains('Dessert')) {
              currentCourse = cleanedText;
            } else if (currentCourse != null &&
                !cleanedText.contains('Non Disponibili') &&
                cleanedText.isNotEmpty) {
              if (foundPranzo) {
                lunchCourses[currentCourse]?.add(cleanedText);
              } else if (foundCena) {
                dinnerCourses[currentCourse]?.add(cleanedText);
              }
            }
          }
        }

        // Remove empty entries
        lunchCourses.forEach((key, value) {
          lunchCourses[key] = value.where((item) => item.isNotEmpty).toList();
        });
        dinnerCourses.forEach((key, value) {
          dinnerCourses[key] = value.where((item) => item.isNotEmpty).toList();
        });

        print('Pranzo: $lunchCourses'); // This will print the categorized lunch courses
        print('Cena: $dinnerCourses'); // This will print the categorized dinner courses
      }
      setState(() {});
    } else {
      throw Exception('Impossibile caricare i dati del menù');
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('dd MMMM yyyy', 'it_IT').format(
        DateTime.now());
    TimeOfDay currentTime = TimeOfDay.now();
    bool showLunch = currentTime.hour < 14;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(currentDate, style: Theme
                .of(context)
                .textTheme
                .titleLarge)),
            SizedBox(height: 20),
            _buildCollapsibleSection('Pranzo', lunchCourses, showLunch),
            SizedBox(height: 20),
            _buildCollapsibleSection('Cena', dinnerCourses, !showLunch),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Link'),
                content: Text(_menuUrl),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.link),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildCollapsibleSection(String title,
      Map<String, List<String>> courses, bool initiallyExpanded) {
    return Card(
      color: Theme.of(context).cardColor,
      child: ExpansionTile(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.0),
        collapsedBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.0),
        textColor: Theme.of(context).colorScheme.onPrimary,
        collapsedTextColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(title, style: Theme
            .of(context)
            .textTheme
            .titleLarge),
        initiallyExpanded: initiallyExpanded,
        children: courses.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(entry.key, style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.0), // Use card theme color
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(entry.value[index]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}