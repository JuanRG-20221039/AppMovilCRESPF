import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search.dart';
import 'reading.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ResultsScreen(),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final String? initialQuery; // Permite recibir el texto de búsqueda

  const ResultsScreen({super.key, this.initialQuery});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late Future<List<dynamic>> _futurePdfs;
  List<dynamic> _allPdfs = [];
  List<dynamic> _filteredPdfs = [];
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    print("🧠 initState ejecutado");

    _searchController = TextEditingController(text: widget.initialQuery ?? "");
    _searchController.addListener(_filterResults);

    _futurePdfs = fetchPdfs();
  }

  Future<List<dynamic>> fetchPdfs() async {
    final url = Uri.parse("https://paulofraireback.onrender.com/api/pdfs-cc");
    print("🟢 Iniciando solicitud HTTP a $url");

    final response = await http.get(url);
    print("📡 Respuesta HTTP: ${response.statusCode}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print("✅ Datos recibidos: ${decoded.length} elementos");
      return decoded;
    } else {
      print("❌ Error al cargar PDFs: ${response.body}");
      throw Exception("Error al cargar los PDFs");
    }
  }

  void _filterResults() {
    final query = _searchController.text.trim().toLowerCase();
    print("🔍 Filtrando resultados con query: '$query'");

    if (_allPdfs.isEmpty) return;

    setState(() {
      if (query.isEmpty) {
        _filteredPdfs = List.from(_allPdfs);
        print("📃 Query vacío, mostrando todos los PDFs");
      } else {
        _filteredPdfs = _allPdfs.where((pdf) {
          final name = (pdf["nombre"] ?? "").toString().toLowerCase();
          final description = (pdf["descripcion"] ?? "").toString().toLowerCase();
          final match = name.contains(query) || description.contains(query);
          if (match) print("✅ Coincidencia: ${pdf["nombre"]}");
          return match;
        }).toList();
        print("📊 PDFs filtrados: ${_filteredPdfs.length}");
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterResults);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Evita overflow cuando aparece el teclado
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con buscador
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                            print("🔙 Regresando a SearchScreen");
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Resultados de búsqueda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar libros...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          print("🧹 Limpiando búsqueda");
                          _searchController.clear();
                          _filterResults();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    onSubmitted: (value) {
                      print("📥 Enter presionado con valor: '$value'");
                      _filterResults();
                    },
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
                    print("⌛ Esperando datos del servidor...");
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print("❌ Error: ${snapshot.error}");
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print("📭 No se encontraron PDFs en la API");
                    return const Center(child: Text("No hay resultados disponibles"));
                  } else {
                    if (_allPdfs.isEmpty) {
                      _allPdfs = snapshot.data!;
                      print("📥 PDFs cargados en memoria: ${_allPdfs.length}");

                      // Aplicar filtro inicial sin setState durante build
                      if ((_searchController.text).isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          print("🔎 Aplicando filtro inicial con '${_searchController.text}'");
                          _filterResults();
                        });
                      } else {
                        _filteredPdfs = List.from(_allPdfs);
                      }
                    }

                    if (_filteredPdfs.isEmpty) {
                      print("🚫 No hay coincidencias con la búsqueda actual");
                      return const Center(child: Text("No se encontraron coincidencias"));
                    }

                    print("📚 Mostrando ${_filteredPdfs.length} PDFs filtrados");
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredPdfs.length,
                      itemBuilder: (context, index) {
                        final pdf = _filteredPdfs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: pdf["imagen"] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      pdf["imagen"],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                            title: Text(pdf["nombre"] ?? "Sin título"),
                            subtitle: Text(pdf["descripcion"] ?? ""),
                            tileColor: Colors.grey[200],
                            onTap: () {
                              print("📖 Abriendo PDF: ${pdf["archivo"]}");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReadingScreen(pdfUrl: pdf["archivo"]),
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
