import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_to_text_ftr/components/ImageTextResultPage.dart';
import 'package:path_provider/path_provider.dart'; // Import path_provider.
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit.

class CarAnimationPage extends StatefulWidget {
  @override
  _CarAnimationPageState createState() => _CarAnimationPageState();
}

class _CarAnimationPageState extends State<CarAnimationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  File? _pickedImage;
  String _extractedText = '';
  final ImagePicker _imagePicker = ImagePicker();
  bool isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      _detectNumberPlate(_pickedImage!);
    }
  }

  Future<void> _captureImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      _detectNumberPlate(_pickedImage!);
    }
  }

  Future<void> _detectNumberPlate(File image) async {
    setState(() {
      isLoading = true; // Set loading to true
    });

    final inputImage = InputImage.fromFile(image);

    // Object Detection options for number plates.
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: false,
      multipleObjects: false,
    );

    final objectDetector = ObjectDetector(options: options);
    final List<DetectedObject> objects =
        await objectDetector.processImage(inputImage);

    if (objects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No number plate detected.'),
        ),
      );
      setState(() {
        isLoading = false; // Set loading to false
      });
      return;
    }

    for (DetectedObject detectedObject in objects) {
      final boundingBox = detectedObject.boundingBox;

      final img.Image? originalImage = img.decodeImage(image.readAsBytesSync());
      if (originalImage != null) {
        final croppedImage = img.copyCrop(
          originalImage,
          x: boundingBox.left.toInt(),
          y: boundingBox.top.toInt(),
          width: boundingBox.width.toInt(),
          height: boundingBox.height.toInt(),
        );

        final croppedFile = await _saveCroppedImage(croppedImage);
        await _extractTextFromImage(croppedFile);
      }
      break; // Use only the first detected object as number plate.
    }

    objectDetector.close();
  }

  Future<File> _saveCroppedImage(img.Image image) async {
    final path =
        '${(await getTemporaryDirectory()).path}/cropped_number_plate.jpg';
    final file = File(path);
    file.writeAsBytesSync(img.encodeJpg(image));
    return file;
  }

  Future<void> _extractTextFromImage(File image) async {
    setState(() {
      isLoading = true; // Set loading to true
    });

    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      setState(() {
        _extractedText = recognizedText.text;
      });

      if (_extractedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No text extracted from the number plate.'),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageTextResultPage(
              image: image,
              extractedText: _extractedText,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _extractedText = 'Error recognizing text: $e';
      });
    } finally {
      textRecognizer.close();
      setState(() {
        isLoading = false; // Set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value * screenHeight + 210,
                left: -130,
                child: child!,
              );
            },
            child: Transform.rotate(
              angle: pi / -2,
              child: Image.asset(
                'asset/images/porsche.jpg',
                width: 650,
                fit: BoxFit.fill,
              ),
            ),
          ),
          if (isLoading) // Show spinner if loading
            Center(
              child: SpinKitCircle(
                color: Colors.blue,
                size: 50.0,
              ),
            ),
          if (!isLoading) // Show buttons if not loading
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlowingButton(
                      icon: Icons.photo_library,
                      text: 'Gallery',
                      onPressed: _pickImageFromGallery,
                    ),
                    SizedBox(width: 20),
                    GlowingButton(
                      icon: Icons.camera_alt,
                      text: 'Capture',
                      onPressed: _captureImageFromCamera,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GlowingButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  GlowingButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                spreadRadius: 4,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
