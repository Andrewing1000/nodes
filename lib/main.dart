import 'package:flutter/material.dart';
import 'home.dart';  // Assuming home.dart contains your RenderedBoard widget

void main() {
  runApp(NodesApp());
}

class NodesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nodes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RenderedBoard(),
    );
  }
}