import 'package:flutter/material.dart';
import 'package:mlkit/mlkit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseVisionTextDetector detector;
  List currentLabels;
  List ingredients;


  @override
  void initState() {
    super.initState();
    detector = FirebaseVisionTextDetector.instance;
    currentLabels = [];
    ingredients = [];
  }

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: new AppBar(

        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Expanded(
                child: currentLabels.length == 0
                    ? new Text("no text")
                    : new ListView.builder(
                  itemBuilder: (BuildContext context, int index) =>
                  new Column(
                    children: <Widget>[
                      new Text(currentLabels[index].text),
                    ],
                  ),
                  itemCount: currentLabels.length,)
            ),
            new Expanded(
                child: ingredients.length == 0
                    ? new Text("no text")
                    : new ListView.builder(
                  itemBuilder: (BuildContext context, int index) =>
                  new Column(
                    children: <Widget>[
                      new Text(ingredients[index].toString()),
                    ],
                  ),
                  itemCount: ingredients.length,)
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: analyzePicture,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void analyzePicture() async{
    var resultList = [];
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    var textList = await detector.detectFromPath(image?.path);
    setState(() {
      currentLabels = textList;
    });
    await Future.forEach(textList, (text) async{
      var inputString = text.text;
      var result = await http.get(
        'https://api.edamam.com/api/nutrition-data?app_id=be779c43&app_key=42d7a3fee3bbda47cbbaf4db31875046&ingr=$inputString',);
      var resultJson = await json.decode(result.body);
      resultList.add(resultJson["totalNutrients"]["FAT"]["quantity"]);
    });

    setState(() {
      ingredients = resultList;
    });
  }
}
