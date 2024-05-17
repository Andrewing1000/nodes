import 'package:flutter/material.dart';
import 'package:nodes/home.dart';

void main(){
  return runApp(NodesApp());
}

class NodesApp extends StatelessWidget{

  const NodesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RenderedBoard();
  }
}