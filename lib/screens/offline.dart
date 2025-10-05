import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'login.dart';
import 'reading.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: OfflineScreen());
  }
}

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  List<FileSystemEntity> downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) => f.path.endsWith(".pdf")).toList();
    setState(() {
      downloadedFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar con buscador
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Lectura sin conexión',
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
                      hintText: 'Buscar libros descargados...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: const Icon(Icons.mic, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Resultados de libros descargados
            Expanded(
              child: downloadedFiles.isEmpty
                  ? const Center(child: Text("No hay libros descargados"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: downloadedFiles.length,
                      itemBuilder: (context, index) {
                        final file = downloadedFiles[index];
                        final fileName = file.path.split('/').last;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.book),
                            title: Text(fileName),
                            tileColor: Colors.grey[200],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReadingScreen(
                                    pdfUrl: file.path,
                                    title: fileName,
                                  ),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await file.delete();
                                  setState(() {
                                    downloadedFiles.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Archivo eliminado con éxito',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al eliminar el archivo: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
