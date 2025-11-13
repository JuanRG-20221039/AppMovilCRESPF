import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
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
  static const String guardianApiKey = 'e5d073f2-7ce0-4387-8510-04b6d18f5807';
  List<dynamic> _guardianSuggestions = [];
  bool _isLoadingGuardian = false;
  String? _guardianError;
  Timer? _guardianDebounce;

  @override
  void initState() {
    super.initState();
    print("🧠 initState ejecutado");

    _searchController = TextEditingController(text: widget.initialQuery ?? "");
    _searchController.addListener(_onSearchChanged);

    _futurePdfs = fetchPdfs();

    final initQuery = widget.initialQuery?.trim();
    if (initQuery != null && initQuery.isNotEmpty) {
      _fetchGuardianSuggestions(initQuery);
    } else {
      _fetchGuardianSuggestions(null);
    }
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

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    _filterResults();
    _guardianDebounce?.cancel();
    _guardianDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchGuardianSuggestions(text.isEmpty ? null : text);
    });
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

  Future<void> _fetchGuardianSuggestions([String? query]) async {
    final qTrim = query?.trim();
    setState(() {
      _isLoadingGuardian = true;
      _guardianError = null;
    });

    final params = {
      'api-key': guardianApiKey,
      'page-size': '5',
      'order-by': 'newest',
    };
    if (qTrim != null && qTrim.isNotEmpty) {
      params['q'] = qTrim;
    }
    final uri = Uri.https('content.guardianapis.com', 'search', params);
    print('📰 Solicitando sugerencias Guardian: $uri');

    try {
      final resp = await http.get(uri);
      print('📰 Guardian status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = (data['response']?['results'] ?? []) as List<dynamic>;
        setState(() {
          _guardianSuggestions = results;
        });
        print('📰 Sugerencias Guardian cargadas: ${_guardianSuggestions.length}');
      } else {
        setState(() {
          _guardianError = 'Guardian error ${resp.statusCode}';
          _guardianSuggestions = [];
        });
        print('❌ Guardian error body: ${resp.body}');
      }
    } catch (e) {
      setState(() {
        _guardianError = e.toString();
        _guardianSuggestions = [];
      });
      print('❌ Excepción Guardian: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGuardian = false;
        });
      }
    }
  }

  Future<void> _openGuardianArticle(String url) async {
    print('🌐 Abriendo artículo en navegador: $url');
    try {
      final uri = Uri.parse(url.trim());
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        print('❌ No se pudo abrir el navegador para: $url');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el navegador')),
        );
      }
    } catch (e) {
      print('❌ Error al abrir en navegador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir el navegador')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _guardianDebounce?.cancel();
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
                          _fetchGuardianSuggestions(null);
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
                      _fetchGuardianSuggestions(value);
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
                    final pdfCards = _filteredPdfs.map((pdf) {
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
                    }).toList();

                    final guardianSection = <Widget>[
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        children: const [
                          Icon(Icons.public, color: Colors.black54),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sugerencias externas (The Guardian)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingGuardian)
                        const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (_guardianError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Error cargando sugerencias: $_guardianError'),
                        )
                      else if (_guardianSuggestions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No hay sugerencias disponibles por ahora'),
                        )
                      else
                        ..._guardianSuggestions.map((item) {
                          final title = (item['webTitle'] ?? '').toString();
                          final section = (item['sectionName'] ?? '').toString();
                          final webUrl = (item['webUrl'] ?? '').toString();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.article, color: Colors.blueGrey, size: 32),
                              title: Text(title),
                              subtitle: Text(section.isNotEmpty ? section : 'The Guardian'),
                              onTap: () => _openGuardianArticle(webUrl),
                            ),
                          );
                        }).toList(),
                    ];

                    return ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        ...pdfCards,
                        ...guardianSection,
                      ],
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
