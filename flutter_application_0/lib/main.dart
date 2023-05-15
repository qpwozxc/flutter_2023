import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('my first app'),
        centerTitle: true,
      ),
      //as
      body: Center(
        child: Text('hello'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text('click'),
        onPressed: () {
          print('FloatingActionButton is pressed!');
        },
      ),
    ),
  ));
}
