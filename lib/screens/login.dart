import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service_stub.dart'
    if (dart.library.html) '../services/auth_service_web.dart'
    if (dart.library.io) '../services/auth_service_mobile.dart';
import 'search.dart';
import 'offline.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      debugPrint('[LoginScreen] Inicio de flujo Google Sign-In. kIsWeb=${kIsWeb}');
      final beforeUser = FirebaseAuth.instance.currentUser;
      debugPrint('[LoginScreen] Usuario antes de iniciar: ${beforeUser?.uid ?? 'null'} | email=${beforeUser?.email ?? 'null'}');

      await signInWithGoogle(context);

      final user = FirebaseAuth.instance.currentUser;
      debugPrint('[LoginScreen] Google Sign-In completado. uid=${user?.uid ?? 'null'} | email=${user?.email ?? 'null'} | providers=${user?.providerData.map((p) => p.providerId).toList()} | isAnonymous=${user?.isAnonymous}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesión iniciada correctamente')),
        );
        debugPrint('[LoginScreen] Navegando a SearchScreen');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      }
    } catch (e) {
      // Captura del error y el stack trace para diagnóstico
      debugPrint('[LoginScreen] Error al iniciar sesión con Google: $e');
      // Intentamos obtener stack trace si está disponible
      try {
        throw e; // fuerza generación de stack en algunos entornos
      } catch (err, st) {
        debugPrint('[LoginScreen] Stacktrace: $st');
      }
      final current = FirebaseAuth.instance.currentUser;
      debugPrint('[LoginScreen] Usuario actual tras error: ${current?.uid ?? 'null'} | email=${current?.email ?? 'null'}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.green,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo y título
              Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.people, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'CRESPF',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Biblioteca Digital',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Formulario de login
              Container(
                padding: EdgeInsets.all(16.0),
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Usuario:',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      controller: TextEditingController(),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Contraseña:',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      controller: TextEditingController(),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Entrar'),
                    ),
                    SizedBox(height: 10),

                    // Ir a lectura sin conexión
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OfflineScreen()),
                        );
                      },
                      child: Text(
                        'Lectura sin conexión',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Login con Google
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Iniciar sesión con:',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('[LoginScreen] Botón Google presionado');
                      _signInWithGoogle(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 18,
                      height: 18,
                    ),
                    label: const Text('Google'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
