import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './classifier/classifier.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랄라 신나는 장바구니 확인',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const HomeChecker(),
    );
  }
}

enum _ResultStatus {
  notStarted,
  notFound,
  found,
}

class HomeChecker extends StatefulWidget {
  const HomeChecker({super.key});

  @override
  State<HomeChecker> createState() => _HomeCheckerState();
}

class _HomeCheckerState extends State<HomeChecker> {
  Classifier? _classifier;
  File? _image;
  final picker = ImagePicker();
  Image? _imageWidget;

  _ResultStatus _resultStatus = _ResultStatus.notStarted;
  String _label = '';
  String _accuracy = '';

  @override
  void initState() {
    super.initState();
    _loadClassifier();
  }

  Future<void> _loadClassifier() async {
    _classifier = await Classifier.loadWith(
      labelsFileName: 'assets/labels.txt',
      modelFileName: 'model_unquant.tflite',
    );
  }

  Future getImage() async {
    // final pickedFile = await picker.pickImage(source: ImageSource.gallery); //it doesnt support windows
    File? pickedFile;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      pickedFile = File(result.files.single.path.toString());
      _analyzeImage(File(pickedFile.path));
    }
  }

  void _analyzeImage(File image) {
    final imageInput = img.decodeImage(image.readAsBytesSync())!;

    final resultCategory = _classifier!.predict(imageInput);

    final result = resultCategory.score >= 0.8
        ? _ResultStatus.found
        : _ResultStatus.notFound;
    final plantLabel = resultCategory.label;
    final accuracy = resultCategory.score;

    setState(() {
      _resultStatus = result;
      _label = plantLabel;
      _accuracy = accuracy.toStringAsFixed(2);
      _image = image;
      _imageWidget = Image.file(_image!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TfLite Flutter Helper',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: _image == null
                ? const Text('No image selected.')
                : Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 2),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: _imageWidget,
                  ),
          ),
          const SizedBox(
            height: 36,
          ),
          Text(
            _label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 8,
          ),
          if (_accuracy.isNotEmpty)
            Text(
              'Accuracy: $_accuracy',
              style: const TextStyle(fontSize: 16),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
