import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:tflite/tflite.dart';
import 'package:http/http.dart' as http;

class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  File? _image;

  late List _result;
  String _name = "";
  String _confidence = "";

  Future getImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      final imagePermanent = await saveFilePermanently(image.path);

      setState(() {
        this._image = imagePermanent;
      });
    } on PlatformException catch (e) {
      print("Failed To Pick Image: $e");
    }
  }

  loadModel() async {
    var prediction_model = await Tflite.loadModel(
        labels: "assets/labels.txt", model: "assets/model.tflite");

    print("Model verdict: $prediction_model");
  }

  applyModelOnImage(File file) async {
    var API = 'python imdb.py';
    var prediction = await Tflite.runModelOnImage(
        path: file.path,
        numResults: 7,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);

    setState(() async {
      _result = prediction!;

      print(_result[0]["label"]);

        var emotion = _result[0]["label"];

        final url = 'http://127.0.0.1:8080/'; 
        final response = await http.post(
          Uri.parse(url),
          body: json.encode({'sentiment': emotion}),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          List<dynamic> movies = json.decode(response.body);
          print(movies);
        } else {
          throw Exception('Failed to load movies');
        }
      });
    }

  Future<File> saveFilePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = basename(imagePath);
    final image = File('${directory.path}/$name');

    loadModel();
    applyModelOnImage(image);

    return File(imagePath).copy(image.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
          child: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          _image != null
              ? Image.file(
                  _image!,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  "https://mkpusa.org/wp-content/uploads/2015/04/YourFace.jpg"),
          SizedBox(
            height: 100,
          ),
          CustomButton(
            title: "Pick From Gallery",
            icon: Icons.image_outlined,
            onClick: () => getImage(ImageSource.gallery),
          ),
          SizedBox(
            height: 20,
          ),
          CustomButton(
            title: "Take A Photo",
            icon: Icons.camera_alt,
            onClick: () => getImage(ImageSource.camera),
          ),
        ],
      )),
    );
  }
}

Widget CustomButton({
  required VoidCallback onClick,
  required String title,
  required IconData icon,
}) {
  return Container(
    width: 200,
    child: ElevatedButton(
      onPressed: onClick,
      child: Row(
        children: [
          Icon(icon),
          SizedBox(
            width: 20,
          ),
          Text(title)
        ],
      ),
    ),
  );
}
