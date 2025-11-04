import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Flujo móvil usando FirebaseAuth con GoogleAuthProvider (abre navegador/Custom Tab).
Future<void> signInWithGoogle(BuildContext context) async {
  try {
    debugPrint('[AuthMobile] Iniciando signInWithProvider GoogleAuthProvider');
    final provider = GoogleAuthProvider();

    final userCred = await FirebaseAuth.instance.signInWithProvider(provider);
    debugPrint('[AuthMobile] Firebase signInWithProvider OK uid=${userCred.user?.uid} email=${userCred.user?.email}');
  } catch (e, st) {
    debugPrint('[AuthMobile] Error en signInWithProvider: $e');
    debugPrint('[AuthMobile] Stacktrace: $st');
    rethrow;
  }
}
