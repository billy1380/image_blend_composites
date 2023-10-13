import 'dart:async';

import 'package:blend_composites/blend_composites.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_blend_composites/blend_composite.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Blending mode Demo",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Blending Mode"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BlendingMode _selectedBlendMode = BlendingMode.normal;

  void _changeBlendMode(BlendingMode m) {
    setState(() {
      _selectedBlendMode = m;
      _blendImages();
    });
  }

  Future<Uint8List> _blendImages() async {
    setState(() {});

    final Uint8List imageA = await _getImageA();
    final Uint8List imageB = await _getImageB();

    BlendComposite c = BlendComposite.getInstance(_selectedBlendMode);
    return c.compose(imageA, imageB);
  }

  Future<Uint8List> _getImageA() => _getImage("images/A.png");
  Future<Uint8List> _getImageB() => _getImage("images/B.png");

  Future<Uint8List> _getImage(String assetName) async =>
      (await rootBundle.load(assetName)).buffer.asUint8List();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Selecte a blending Mode",
            ),
            DropdownButton<int>(
              value: _selectedBlendMode.index,
              items: BlendingMode.values
                  .map((BlendingMode b) => DropdownMenuItem<int>(
                        value: b.index,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(b.name),
                        ),
                      ))
                  .toList(),
              onChanged: (value) =>
                  _changeBlendMode(BlendingMode.values[value ?? 0]),
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: _blendImages(),
              builder: (context, snapshot) => snapshot.hasData
                  ? Image.memory(snapshot.data!)
                  : const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
