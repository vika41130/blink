import 'package:blink/app.dart';
import 'package:blink/firebase_options.dart';
import 'package:blink/get_it_setup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await getItSetup();

  return runApp(BlinkApp());
}
