import 'package:flutter/material.dart';
import 'login.dart';
import 'reading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: OfflineScreen());
  }
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with Back Button and Title
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
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
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Lectura sin conexión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar libros descargados...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Icon(Icons.mic, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ],
              ),
            ),
            // Search Results
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  ListTile(
                    leading: Icon(Icons.book),
                    title: Text('Libro offline 1'),
                    tileColor: Colors.grey[200],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadingScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
