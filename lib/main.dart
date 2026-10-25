import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  runApp(const MyApp());
}

/// Public root widget retained for compatibility with the project template.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const App();
}
