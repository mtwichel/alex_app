import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlkit/mlkit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';



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

  DBHelper _dbHelper;
  Database _db;

  @override
  void initState(){
    super.initState();
    detector = FirebaseVisionTextDetector.instance;
    currentLabels = [];
    ingredients = [];

    _dbHelper = new DBHelper();
    _dbHelper.getDb().then((db) {
      _db = db;
      print("Got db");
    });
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
      print(parseResult.ingredient);
      var nutrientMap = await searchDB(db: _db, input: parseResult.ingredient);
      if(nutrientMap != null || nutrientMap.length != 0){
        resultList.add(new Ingredient(title: parseResult.ingredient, fat: nutrientMap[0]));
      }
    });

    setState(() {
      ingredients = resultList;
    });
  }

  searchDB({input, Database db}) async{
    List<Map> list = await db.rawQuery('SELECT * FROM nutrients WHERE Descrip LIKE \'%$input%\'');
    print(list);
    return list;
  }
}

class IngredientView extends StatelessWidget{
  IngredientView({this.ingredient});

  final Ingredient ingredient;

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

class DBHelper {
  String path;
  DBHelper();
  Database _db;
  final _lock = new Lock();

  Future<Database> getDb() async {

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, "asset_nutrients.db");

    // delete existing if any
    await deleteDatabase(path);

    // Copy from asset
    ByteData data = await rootBundle.load(join("assets", "nutrients.db"));
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await new File(path).writeAsBytes(bytes);

    if (_db == null) {
      await _lock.synchronized(() async {
        // Check again once entering the synchronized block
        if (_db == null) {
          _db = await openReadOnlyDatabase(path);
        }
      });
    }
    return _db;
  }
}