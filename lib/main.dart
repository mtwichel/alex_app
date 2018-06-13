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
  File _image;
  List<VisionText> currentLabels;
  List ingredients;


  @override
  void initState() {
    // TODO: implement initState
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
            new RaisedButton(
              child: new Text("Get Image"),
              onPressed:() async{
                var image = await ImagePicker.pickImage(source: ImageSource.camera);
                var textList = await detector.detectFromPath(image?.path);
                var dataString = list2String(list: textList);
                var result = await http.post(
                  'https://spoonacular-recipe-food-nutrition-v1.p.mashape.com/recipes/parseIngredients?includeNutrition=true',
                  headers: {'X-Mashape-Key': '7lqJ5Hl4RJmshs4bsOyrsroUiH2cp1pwFfjjsnU7UssW1DWdF3'},
                  body: {'ingredientList': dataString, 'servings': "1"},
                );
                List resultJson = json.decode(result.body);
                setState(() {
                  ingredients = resultJson;
                });
              },
            ),
            new Expanded(child: ingredients.length == 0
                ? new Text("no text")
                : new ListView.builder(
              itemBuilder: (BuildContext context, int index) =>
              new Text("hi"),
              itemCount: ingredients.length,)
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: null,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  String list2String({List<VisionText> list}) {
    var ans = "";
    list.forEach((item) {
      ans += "${item.text}\n";
    });
    return ans;
  }

}

class Ingredient {
  final String name;
  final num amount;
  final String unit;
  final Nutrition nutrition;

  Ingredient({this.name, this.amount, this.unit, this.nutrition,});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return new Ingredient(
      name: json['name'],
      amount: json['amount'],
      unit: json['unit'],
      nutrition: json['nutrition'],
    );
  }
}

class Nutrition {
  final List<Nutrient> nutrients;

  Nutrition({this.nutrients});

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return new Nutrition(
      nutrients: json['nutrients'],
    );
  }
}

class Nutrient {
  final String title;
  final double amount;

  Nutrient({this.title, this.amount});

  factory Nutrient.fromJson(Map<String, dynamic> json) {
    return new Nutrient(
      title: json['title'],
      amount: json['amount'],
    );
  }
}