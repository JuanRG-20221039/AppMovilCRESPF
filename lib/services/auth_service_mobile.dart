import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

// Flujo móvil nativo usando el plugin google_sign_in (selector de cuenta dentro de la app).
Future<void> signInWithGoogle(BuildContext context) async {
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      debugPrint('[AuthMobile] Iniciando GoogleSignIn v7 (flujo nativo dentro de la app)');

      const scopes = <String>['email'];
      final googleSignIn = GoogleSignIn.instance;

      // v7 requiere inicializar explícitamente antes de usar.
      await googleSignIn.initialize();

      // En v7 se usa authenticate() en lugar de signIn().
      final GoogleSignInAccount? account = await googleSignIn.authenticate(
        scopeHint: scopes,
      );

      if (account == null) {
        throw Exception('Inicio de sesión cancelado por el usuario');
      }

      // En v7 el accessToken de autenticación puede no estar disponible;
      // para FirebaseAuth basta con el idToken.
      final GoogleSignInAuthentication auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[AuthMobile] Firebase signInWithCredential OK uid=${userCred.user?.uid} email=${userCred.user?.email}');
    } else {
      // Fallback para plataformas de escritorio que no soportan google_sign_in nativo.
      debugPrint('[AuthMobile] Plataforma no móvil, usando signInWithProvider (puede abrir navegador)');
      final provider = GoogleAuthProvider();
      final userCred = await FirebaseAuth.instance.signInWithProvider(provider);
      debugPrint('[AuthMobile] Firebase signInWithProvider OK uid=${userCred.user?.uid} email=${userCred.user?.email}');
    }
  } catch (e, st) {
    debugPrint('[AuthMobile] Error en GoogleSignIn nativo: $e');
    debugPrint('[AuthMobile] Stacktrace: $st');
    rethrow;
  }
}
