import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageTextResultPage extends StatefulWidget {
  final File image;
  final String extractedText;

  const ImageTextResultPage({
    required this.image,
    required this.extractedText,
  });

  @override
  State<ImageTextResultPage> createState() => _ImageTextResultPageState();
}

class _ImageTextResultPageState extends State<ImageTextResultPage> {
  late String validatedText;
  Map<String, dynamic>? vehicleData;

  @override
  void initState() {
    super.initState();
    validatedText = _validateRegistrationNumber(widget.extractedText);
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8000/vehicles'));

      if (response.statusCode == 200) {
        List<dynamic> vehicles = json.decode(response.body);
        print(
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" +
                validatedText);
        validatedText = validatedText.replaceAll(" ", "");
        vehicleData = vehicles.firstWhere(
            (vehicle) => vehicle['plateNumber'] == validatedText,
            orElse: () => defaultVehicleData());
      } else {
        throw Exception('Failed to load vehicle data');
      }
      setState(() {});
    } catch (e) {
      print(e);
      vehicleData = defaultVehicleData();
      setState(() {});
    }
  }

  Map<String, dynamic> defaultVehicleData() {
    return {
      "plateNumber": "Not Found",
      "ownerName": "Unknown",
      "vehicleType": "N/A",
      "engineNumber": "N/A",
      "chassisNumber": "N/A",
      "regYear": "N/A",
      "legalInfo": "No Data Available"
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Extracted Text Result'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(
              255, 247, 247, 247), // Light background for neumorphism
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              offset: Offset(-10, -10),
              blurRadius: 20,
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              offset: Offset(10, 10),
              blurRadius: 20,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Display the selected image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
                image: DecorationImage(
                  image: FileImage(widget.image),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Display the extracted text and vehicle details in cards
            Expanded(
              child: SingleChildScrollView(
                child: vehicleData != null
                    ? Column(
                        children: [
                          _buildDataCard('Registration Number',
                              vehicleData!['plateNumber']),
                          _buildDataCard(
                              'Owner Name', vehicleData!['ownerName']),
                          _buildDataCard(
                              'Vehicle Type', vehicleData!['vehicleType']),
                          _buildDataCard(
                              'Engine Number', vehicleData!['engineNumber']),
                          _buildDataCard(
                              'Chassis Number', vehicleData!['chassisNumber']),
                          _buildDataCard(
                              'Registration Year', vehicleData!['regYear']),
                          _buildDataCard(
                              'Legal Info', vehicleData!['legalInfo']),
                        ],
                      )
                    : Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build a neomorphic card with fixed width
  Widget _buildDataCard(String title, String data) {
    return SizedBox(
      width: 350, // Set a fixed width for all cards
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFE0E5EC), // Light background for neumorphism
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              offset: Offset(-8, -8),
              blurRadius: 15,
            ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              offset: Offset(8, 8),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              data,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to validate the extracted text using regex
  String _validateRegistrationNumber(String text) {
    // Step 1: Replace hyphens with whitespace
    String formattedText = text.replaceAll('-', ' ');

    // Step 2: Ensure it starts with two capital letters
    if (formattedText.length > 2) {
      formattedText = formattedText.trim();
    }

    // Step 3: Define the regex pattern for validation
    String pattern = r'^[A-Z]{2}\s\d{2}\s[A-Z]{1}\s\d{4}$';
    RegExp regex = RegExp(pattern);

    // Split the text into parts
    List<String> parts = formattedText.split(RegExp(r'\s+'));

    // Step 4: Handle the format based on conditions
    if (parts.length >= 4) {
      // If there are more than 4 parts, keep only the first 4.
      formattedText = '${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}';
    } else if (parts.length == 3) {
      // If there are 3 parts, keep them as is.
      formattedText = '${parts[0]} ${parts[1]} ${parts[2]}';
    } else if (parts.length == 2) {
      // If there are only 2 parts, ensure they are valid
      formattedText = '${parts[0]} ${parts[1]}';
    } else if (parts.length == 1) {
      // If there is only 1 part, it's invalid for registration
      return '';
    }

    // Step 5: Check the final formatted text against the regex
    if (regex.hasMatch(formattedText)) {
      return formattedText.trim(); // Return the valid registration number
    } else {
      return ''; // Return an empty string if not valid
    }
  }
}
