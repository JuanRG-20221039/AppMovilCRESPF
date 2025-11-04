import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> signInWithGoogle(BuildContext context) async {
  await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
}

