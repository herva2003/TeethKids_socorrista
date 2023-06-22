import 'package:flutter/material.dart';
import 'package:teethkids_socorrista2/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:teethkids_socorrista2/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  UserCredential? userCredential;

  try {
    userCredential = await FirebaseAuth.instance.signInAnonymously();
    print("Signed in with temporary account.");
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        print("Anonymous auth hasn't been enabled for this project.");
        break;
      default:
        print("Unknown error.");
    }
  }

  runApp(MyApp(userCredential: userCredential));
}

class MyApp extends StatelessWidget {
  final UserCredential? userCredential;

  const MyApp({Key? key, this.userCredential}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String userId = userCredential?.user?.uid ?? '';

    return MaterialApp(
      title: 'Imagens',
      theme: ThemeData(
        primarySwatch: primary,
      ),
      home: HomePage(userId: userId),
    );
  }
}
