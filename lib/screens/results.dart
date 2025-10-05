import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search.dart';
import 'reading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ResultsScreen(),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<List<dynamic>> _futurePdfs;

  Future<List<dynamic>> fetchPdfs() async {
    final url = Uri.parse("https://paulofraireback.onrender.com/api/pdfs-cc");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      throw Exception("Error al cargar los PDFs");
    }
  }

  @override
  void initState() {
    super.initState();
    _futurePdfs = fetchPdfs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar con buscador
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              color: Colors.green,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Resultados de búsqueda',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar libros...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ],
              ),
            ),
            // Lista de resultados
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futurePdfs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No hay resultados disponibles"));
                  } else {
                    final pdfs = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: pdfs.length,
                      itemBuilder: (context, index) {
                        final pdf = pdfs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: pdf["imagen"] != null
                                ? Image.network(
                                    pdf["imagen"],
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(pdf["nombre"] ?? "Sin título"),
                            subtitle: Text(pdf["descripcion"] ?? ""),
                            tileColor: Colors.grey[200],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReadingScreen(pdfUrl: pdf["archivo"]),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
