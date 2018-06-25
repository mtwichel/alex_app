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
                child: ingredients.length == 0
                    ? new Text("no text")
                    : new ListView.builder(
                  itemBuilder: (BuildContext context, int index) =>
                  new Column(
                    children: <Widget>[
                      new IngredientView(
                        ingredient: ingredients[index],
                      ),
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
        child: new Icon(Icons.camera_alt),
      ),
    );
  }

  void analyzePicture() async{
    var resultList = [];
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    var textList = await detector.detectFromPath(image?.path);
    print("Image Processed");
    setState(() {
      currentLabels = textList;
    });
    await Future.forEach(textList, (text) async{
      print(text.text);
      var inputString = text.text;
      var response = await http.get(
        'https://us-central1-alexapp-c6344.cloudfunctions.net/analyzeRecipe?input=$inputString',);
      var resultJson = await json.decode(response.body);
      var parseResult = new ParseResult.fromJson(resultJson);
      resultList.add(new Ingredient(title: parseResult.ingredient));
    });

    setState(() {
      ingredients = resultList;
    });
  }
}

class IngredientView extends StatelessWidget{
  IngredientView({this.ingredient});

  var ingredient;

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Text(ingredient.title.toString()),
        new Center(
          child: new Table(
            columnWidths: {
              0: new FractionColumnWidth(0.3),
              1: new FractionColumnWidth(0.3),
            },
            children: [
              TableRow(
                  children: [
                    new Text("Calories"),
                    new Text(ingredient.calories.toString()),
                  ]
              ),
              TableRow(
                  children: [
                    new Text("Fat"),
                    new Text(ingredient.calories.toString()),
                  ]
              ),
              TableRow(
                  children: [
                    new Text("Sugar"),
                    new Text(ingredient.sugars.toString()),
                  ]
              ),
              TableRow(
                  children: [
                    new Text("Protein"),
                    new Text(ingredient.protein.toString()),
                  ]
              ),
              TableRow(
                  children: [
                    new Text("Carbs"),
                    new Text(ingredient.carbs.toString()),
                  ]
              ),
              TableRow(
                  children: [
                    new Text("Sodium"),
                    new Text(ingredient.sodium.toString()),
                  ]
              ),
              TableRow(
                  children: [
                    new Text("Fiber"),
                    new Text(ingredient.fiber.toString()),
                  ]
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class Ingredient{
  var title;
  var calories;
  var fat;
  var carbs;
  var sugars;
  var protein;
  var sodium;
  var fiber;

  Ingredient({
    this.calories,
    this.fat,
    this.carbs,
    this.sugars,
    this.protein,
    this.sodium,
    this.fiber,
    this.title,
    });
}

class ParseResult{
  num quantity;
  String unit;
  String ingredient;

  ParseResult.fromJson(Map<String, dynamic> json)
      : quantity = json['quantity']==null ? null : num.parse(json['quantity']),
        unit = json['unit'],
        ingredient = json['ingredient'];
}
